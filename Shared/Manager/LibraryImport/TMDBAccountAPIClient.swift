//
//  TMDBAccountAPIClient.swift
//  Cronica
//

import Foundation
import CronicaCore

actor TMDBAccountAPIClient {
    static let shared = TMDBAccountAPIClient()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    struct TokenResponse: Decodable {
        let success: Bool?
        let requestToken: String?
        let expiresAt: String?
    }

    struct SessionResponse: Decodable {
        let success: Bool?
        let sessionId: String?
    }

    struct AccountDetails: Decodable {
        let id: Int
        let username: String?
        let name: String?
    }

    struct PagedItems: Decodable {
        let page: Int?
        let totalPages: Int?
        let results: [AccountMediaItem]?
    }

    struct AccountMediaItem: Decodable {
        let id: Int
        let title: String?
        let name: String?
        let releaseDate: String?
        let firstAirDate: String?
        let rating: Double?
    }

    private init() {}

    func createRequestToken() async throws -> String {
        let url = try url(path: "authentication/token/new")
        let response: TokenResponse = try await get(url)
        guard let token = response.requestToken, response.success != false else {
            throw LibraryImportError.invalidResponse
        }
        return token
    }

    func createSession(requestToken: String) async throws -> String {
        let url = try url(path: "authentication/session/new")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["request_token": requestToken])
        let response: SessionResponse = try await send(request)
        guard let sessionID = response.sessionId, response.success != false else {
            throw LibraryImportError.invalidResponse
        }
        return sessionID
    }

    func accountDetails(sessionID: String) async throws -> AccountDetails {
        let url = try url(path: "account", query: ["session_id": sessionID])
        return try await get(url)
    }

    func pagedAccountList(
        path: String,
        sessionID: String,
        accountID: Int
    ) async throws -> [AccountMediaItem] {
        var page = 1
        var totalPages = 1
        var items: [AccountMediaItem] = []
        while page <= totalPages {
            let url = try url(
                path: "account/\(accountID)/\(path)",
                query: [
                    "session_id": sessionID,
                    "page": "\(page)",
                    "language": Locale.userLang
                ]
            )
            let response: PagedItems = try await get(url)
            items.append(contentsOf: response.results ?? [])
            totalPages = max(response.totalPages ?? 1, 1)
            page += 1
            if page > 50 { break } // safety cap
        }
        return items
    }

    // MARK: - Writes (require session)

    struct StatusResponse: Decodable {
        let success: Bool?
        let statusCode: Int?
        let statusMessage: String?
    }

    func setWatchlist(mediaType: String, mediaID: Int, watchlist: Bool) async throws {
        let (sessionID, accountID) = try sessionCredentials()
        let url = try url(path: "account/\(accountID)/watchlist", query: ["session_id": sessionID])
        try await postJSON(
            url,
            body: [
                "media_type": mediaType,
                "media_id": mediaID,
                "watchlist": watchlist
            ]
        )
    }

    func setFavorite(mediaType: String, mediaID: Int, favorite: Bool) async throws {
        let (sessionID, accountID) = try sessionCredentials()
        let url = try url(path: "account/\(accountID)/favorite", query: ["session_id": sessionID])
        try await postJSON(
            url,
            body: [
                "media_type": mediaType,
                "media_id": mediaID,
                "favorite": favorite
            ]
        )
    }

    /// TMDB ratings are 0.5–10 in half-star steps.
    func setRating(mediaType: String, mediaID: Int, value: Double) async throws {
        let sessionID = try requireSessionID()
        let clamped = max(0.5, min(10, value))
        let url = try url(path: "\(mediaType)/\(mediaID)/rating", query: ["session_id": sessionID])
        try await postJSON(url, body: ["value": clamped])
    }

    func deleteRating(mediaType: String, mediaID: Int) async throws {
        let sessionID = try requireSessionID()
        let url = try url(path: "\(mediaType)/\(mediaID)/rating", query: ["session_id": sessionID])
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        let _: StatusResponse = try await send(request)
    }

    /// Best-effort remote session invalidation.
    func deleteSession(sessionID: String) async throws {
        let url = try url(path: "authentication/session")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["session_id": sessionID])
        let _: StatusResponse = try await send(request)
    }

    private func sessionCredentials() throws -> (String, Int) {
        guard let sessionID = TMDBSessionStore.loadSessionID() else {
            throw LibraryImportError.message("Connect a TMDB account first.")
        }
        let accountID = TMDBSessionStore.loadAccountID()
        guard accountID != 0 else {
            throw LibraryImportError.message("TMDB account id missing. Disconnect and sign in again.")
        }
        return (sessionID, accountID)
    }

    private func requireSessionID() throws -> String {
        guard let sessionID = TMDBSessionStore.loadSessionID() else {
            throw LibraryImportError.message("Connect a TMDB account first.")
        }
        return sessionID
    }

    private func postJSON(_ url: URL, body: [String: Any]) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let _: StatusResponse = try await send(request)
    }

    private func url(path: String, query: [String: String] = [:]) throws -> URL {
        guard Key.isConfigured else { throw LibraryImportError.notConfigured }
        var component = URLComponents()
        component.scheme = "https"
        component.host = "api.themoviedb.org"
        component.path = "/3/\(path)"
        var items = [URLQueryItem(name: "api_key", value: Key.tmdbApi)]
        for (key, value) in query {
            items.append(URLQueryItem(name: key, value: value))
        }
        component.queryItems = items
        guard let url = component.url else { throw LibraryImportError.invalidResponse }
        return url
    }

    private func get<T: Decodable>(_ url: URL) async throws -> T {
        try await send(URLRequest(url: url))
    }

    private func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw LibraryImportError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw LibraryImportError.message("TMDB request failed (\(http.statusCode)).")
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw LibraryImportError.invalidResponse
        }
    }
}
