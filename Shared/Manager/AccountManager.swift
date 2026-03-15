//
//  TMDBAccountManager.swift
//  Cronica
//
//  Created by Alexandre Madeira on 21/04/23.
//

import Foundation

/// This class has all functions required to manage sign-in and sign-out workflows for TMDB accounts.
class AccountManager: ObservableObject {
    static let shared = AccountManager()
    private let contentTypeHeader = "application/json;charset=utf-8"
    private let decoder = JSONDecoder()
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy,MM,dd"
        return formatter
    }()
    private var requestToken = String()
    private var userAccessToken = String()
    private var userAccessId = String()
    private var userSessionId = String()
    
    private init() {
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .formatted(AccountManager.dateFormatter)
        populateAccess()
    }
    
    private func populateAccess() {
        let data = KeychainHelper.standard.read(service: "access-token", account: "cronicaTMDB-Sync")
        let IdData = KeychainHelper.standard.read(service: "access-id", account: "cronicaTMDB-Sync")
        let session = KeychainHelper.standard.read(service: "session-idV3", account: "cronicaTMDB-Sync")
        guard let data else { return }
        let accessToken = String(data: data, encoding: .utf8)
        guard let accessToken else { return }
        userAccessToken = accessToken
        guard let IdData else { return }
        let accessId = String(data: IdData, encoding: .utf8)
        guard let accessId else { return }
        userAccessId = accessId
        let settings = SettingsStore.shared
        if !settings.isUserConnectedWithTMDb {
            DispatchQueue.main.async {
                settings.isUserConnectedWithTMDb = true
            }
        }
        guard let session else { return }
        let sessionId = String(data: session, encoding: .utf8)
        guard let sessionId else { return }
        userSessionId = sessionId
    }
    
    func checkAccessStatus() -> Bool {
        if userAccessId.isEmpty && userAccessToken.isEmpty { return false }
        return true
    }
    
    // MARK: Login
    func requestToken() async -> URL? {
        do {
            guard let authorizationHeader = Key.authorizationHeader else { return nil }
            // Fetch and get the request token
            let headers = [
                "content-type": contentTypeHeader,
                "authorization": authorizationHeader
            ]
            let parameters = ["redirect_to": "cronica://"]
            
            let postData = try JSONSerialization.data(withJSONObject: parameters)
            guard let url = URL(string: "https://api.themoviedb.org/4/auth/request_token") else { return nil }
            var request = URLRequest(url: url,
                                     cachePolicy: .useProtocolCachePolicy,
                                     timeoutInterval: 10.0)
            request.httpMethod = "POST"
            request.allHTTPHeaderFields = headers
            request.httpBody = postData
            let (data, _) = try await URLSession.shared.data(for: request)
            let content =  try decoder.decode(RequestTokenTMDB.self, from: data)
            guard let token = content.requestToken else { return nil }
            self.requestToken = token
            
            // Build and return the URL with the request token
            let requestTokenUrl = URL(string: "https://www.themoviedb.org/auth/access?request_token=\(token)")
            return requestTokenUrl
        } catch {
            if Task.isCancelled { return nil }
            return nil
        }
    }
    
    func requestAccess() async throws {
        guard let authorizationHeader = Key.authorizationHeader else { return }
        do {
            let headers = [
                "content-type": contentTypeHeader,
                "authorization": authorizationHeader
            ]
            let parameters = ["request_token": "\(self.requestToken)"]
            let postData = try JSONSerialization.data(withJSONObject: parameters)
            guard let url = URL(string: "https://api.themoviedb.org/4/auth/access_token") else { return }
            var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
            request.httpMethod = "POST"
            request.allHTTPHeaderFields = headers
            request.httpBody = postData
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let content =  try decoder.decode(AccessTokenTMDB.self, from: data)
            saveUserAccess(for: content)
            guard let token = content.accessToken else { return }
            userAccessToken = token
        } catch {
            if Task.isCancelled { return }
            throw NetworkError.invalidRequest
        }
    }
    
    func createV3Session() async {
        do {
            let headers = [
                "content-type": contentTypeHeader,
                "authorization": "Bearer \(userAccessToken)"
            ]
            let parameters = ["access_token": "\(self.userAccessToken)"]
            let postData = try JSONSerialization.data(withJSONObject: parameters)
            guard let requestUrl = URL(string: "https://api.themoviedb.org/3/authentication/session/convert/4?api_key=\(Key.tmdbApi)") else { return }
            var request = URLRequest(url: requestUrl, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
            request.httpMethod = "POST"
            request.allHTTPHeaderFields = headers
            request.httpBody = postData
            let (data, _) = try await URLSession.shared.data(for: request)
            let content = try decoder.decode(TMDBv3.self, from: data)
            guard let id = content.sessionId else { return }
            let sessionID = Data(id.utf8)
            KeychainHelper.standard.save(sessionID, service: "session-id", account: "cronicaTMDB-Sync")
        } catch {
            if Task.isCancelled { return }
        }
    }
    
    // MARK: Logout
    private func logOutV3() async {
        do {
            let parameters = ["session_id": "\(self.userSessionId)"]
            let postData = try JSONSerialization.data(withJSONObject: parameters)
            guard let deleteUrl = URL(string: "https://api.themoviedb.org/3/authentication/session?api_key=\(Key.tmdbApi)") else { return }
            var request = URLRequest(url: deleteUrl,
                                     cachePolicy: .useProtocolCachePolicy,
                                     timeoutInterval: 10.0)
            request.httpMethod = "DELETE"
            request.httpBody = postData
            let (_, _) = try await URLSession.shared.data(for: request)
        } catch {
            if Task.isCancelled { return  }
        }
    }
    
    private func logOutV4() async {
        do {
            let headers = [
                "content-type": contentTypeHeader,
                "authorization": "Bearer \(userAccessToken)"
            ]
            let parameters = ["access_token": "\(userAccessToken)"]
            let postData = try JSONSerialization.data(withJSONObject: parameters)
            guard let url = URL(string: "https://api.themoviedb.org/4/auth/access_token") else { return }
            var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
            request.httpMethod = "DELETE"
            request.allHTTPHeaderFields = headers
            request.httpBody = postData
            let (_, _) = try await URLSession.shared.data(for: request)
        } catch {
            if Task.isCancelled { return }
        }
    }
    
    // MARK: Keychain
    private func saveUserAccess(for user: AccessTokenTMDB) {
        guard let token = user.accessToken else { return }
        guard let id = user.accountId else { return }
        let accessToken = Data(token.utf8)
        let accessId = Data(id.utf8)
        KeychainHelper.standard.save(accessToken, service: "access-token", account: "cronicaTMDB-Sync")
        KeychainHelper.standard.save(accessId, service: "access-id", account: "cronicaTMDB-Sync")
    }
    
    func logOut() async {
        await MainActor.run { SettingsStore.shared.isUserConnectedWithTMDb = false }
        await self.logOutV3()
        await self.logOutV4()
        KeychainHelper.standard.delete(service: "access-token", account: "cronicaTMDB-Sync")
        KeychainHelper.standard.delete(service: "access-id", account: "cronicaTMDB-Sync")
        KeychainHelper.standard.delete(service: "session-id", account: "cronicaTMDB-Sync")
    }
}
