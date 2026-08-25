//
//  SimklAPIClient.swift
//  Cronica
//

import Foundation
import CronicaCore

actor SimklAPIClient {
    static let shared = SimklAPIClient()

    private let session: URLSession
    private let appName = "cronica"
    private let baseURL = URL(string: "https://api.simkl.com")!
    /// SIMKL POST limit: 1 request per second per client.
    private let minimumPOSTInterval: TimeInterval = 1.05
    private var lastPOSTAt: Date?

    private init(session: URLSession = .shared) {
        self.session = session
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var clientID: String {
        Key.simklClientID
    }

    func requireClientID() throws -> String {
        guard Key.isSimklConfigured else { throw SimklError.notConfigured }
        return clientID
    }

    func exchangeCode(
        _ code: String,
        codeVerifier: String?,
        redirectURI: String
    ) async throws -> SimklTokenResponse {
        let id = try requireClientID()
        var body: [String: String] = [
            "grant_type": "authorization_code",
            "code": code,
            "client_id": id,
            "redirect_uri": redirectURI
        ]
        if let codeVerifier {
            body["code_verifier"] = codeVerifier
        }
        return try await postJSON(path: "/oauth/token", body: body, authorized: false)
    }

    func requestPin() async throws -> SimklPinResponse {
        try await get(path: "/oauth/pin", authorized: false)
    }

    func pollPin(userCode: String) async throws -> SimklPinPollResponse {
        try await get(path: "/oauth/pin/\(userCode)", authorized: false)
    }

    func fetchActivities() async throws -> SimklActivitiesResponse {
        try await get(path: "/sync/activities", authorized: true)
    }

    func fetchAllItems(
        type: SimklMediaKind? = nil,
        dateFrom: String? = nil,
        extended: String? = nil,
        includeAllEpisodes: Bool = false,
        episodeWatchedAt: Bool = false
    ) async throws -> SimklAllItemsResponse {
        var query: [URLQueryItem] = []
        if let dateFrom {
            query.append(URLQueryItem(name: "date_from", value: dateFrom))
        }
        if let extended {
            query.append(URLQueryItem(name: "extended", value: extended))
        }
        if includeAllEpisodes {
            query.append(URLQueryItem(name: "include_all_episodes", value: "yes"))
        }
        if episodeWatchedAt {
            query.append(URLQueryItem(name: "episode_watched_at", value: "yes"))
        }
        let path = type.map { "/sync/all-items/\($0.rawValue)" } ?? "/sync/all-items"
        return try await get(path: path, query: query, authorized: true)
    }

    func addToList(_ payload: SimklAddToListPayload) async throws {
        try await postVoid(path: "/sync/add-to-list", body: payload, authorized: true)
    }

    func addHistory(_ payload: SimklHistoryPayload) async throws {
        try await postVoid(path: "/sync/history", body: payload, authorized: true)
    }

    func removeHistory(_ payload: SimklHistoryPayload) async throws {
        try await postVoid(path: "/sync/history/remove", body: payload, authorized: true)
    }

    // MARK: - HTTP

    private func get<T: Decodable>(
        path: String,
        query: [URLQueryItem] = [],
        authorized: Bool
    ) async throws -> T {
        let request = try makeRequest(path: path, method: "GET", query: query, authorized: authorized)
        return try await send(request)
    }

    private func postJSON<T: Decodable>(
        path: String,
        body: [String: String],
        authorized: Bool
    ) async throws -> T {
        try await waitForPOSTSlot()
        var request = try makeRequest(path: path, method: "POST", query: [], authorized: authorized)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return try await send(request)
    }

    private func postVoid<Body: Encodable>(
        path: String,
        body: Body,
        authorized: Bool
    ) async throws {
        try await waitForPOSTSlot()
        var request = try makeRequest(path: path, method: "POST", query: [], authorized: authorized)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        _ = try await sendData(request)
    }

    private func waitForPOSTSlot() async throws {
        if let lastPOSTAt {
            let elapsed = Date().timeIntervalSince(lastPOSTAt)
            if elapsed < minimumPOSTInterval {
                let delay = minimumPOSTInterval - elapsed
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        lastPOSTAt = Date()
    }

    private func makeRequest(
        path: String,
        method: String,
        query: [URLQueryItem],
        authorized: Bool
    ) throws -> URLRequest {
        let url = try endpointURL(path: path, query: query)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("\(appName)/\(appVersion)", forHTTPHeaderField: "User-Agent")
        request.setValue(try requireClientID(), forHTTPHeaderField: "simkl-api-key")
        request.setValue(appName, forHTTPHeaderField: "app-name")
        request.setValue(appVersion, forHTTPHeaderField: "app-version")
        if authorized {
            guard let token = SimklTokenStore.load() else { throw SimklError.notAuthenticated }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func send<T: Decodable>(_ request: URLRequest, isRetry: Bool = false) async throws -> T {
        let data = try await sendData(request, isRetry: isRetry)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw SimklError.invalidResponse
        }
    }

    private func sendData(_ request: URLRequest, isRetry: Bool = false) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw SimklError.invalidResponse }
        if http.statusCode == 401 {
            await MainActor.run {
                SimklTokenStore.delete()
                SettingsStore.shared.isSimklConnected = false
            }
            throw SimklError.notAuthenticated
        }
        if http.statusCode == 400, Self.isRateLimit(data) {
            if !isRetry {
                try await Task.sleep(nanoseconds: 3_000_000_000)
                return try await sendData(request, isRetry: true)
            }
            throw SimklError.rateLimited
        }
        guard (200..<300).contains(http.statusCode) else {
            throw SimklError.httpStatus(http.statusCode)
        }
        return data
    }

    private static func isRateLimit(_ data: Data) -> Bool {
        guard let text = String(data: data, encoding: .utf8)?.lowercased() else { return false }
        return text.contains("rate_limit") || text.contains("rate limit")
    }

    private func endpointURL(path: String, query: [URLQueryItem]) throws -> URL {
        let id = try requireClientID()
        let trimmed = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var components = URLComponents(url: baseURL.appendingPathComponent(trimmed), resolvingAgainstBaseURL: false)!
        var items = query
        items.append(URLQueryItem(name: "client_id", value: id))
        items.append(URLQueryItem(name: "app-name", value: appName))
        items.append(URLQueryItem(name: "app-version", value: appVersion))
        components.queryItems = items
        guard let url = components.url else { throw SimklError.invalidResponse }
        return url
    }
}
