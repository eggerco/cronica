//
//  ExternalWatchlistManager.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 24/04/23.
//

import SwiftUI

/// This class handles with fetching and sync of lists on external services.
///
/// Only TMDb is accepted at the moment.
class ExternalWatchlistManager: ObservableObject {
    static let shared = ExternalWatchlistManager()
    private let contentTypeHeader = "application/json;charset=utf-8"
    private let decoder = JSONDecoder()
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy,MM,dd"
        return formatter
    }()
    private var userAccessToken = String()
    private var userAccessId = String()
    private var userSessionId = String()
    
    @Published var watchlist = [ItemContent]()
    
    private init() {
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .formatted(ExternalWatchlistManager.dateFormatter)
        populateAccess()
    }
    
    private func populateAccess() {
        let data = KeychainHelper.standard.read(service: "access-token", account: "cronicaTMDB-Sync")
        let IdData = KeychainHelper.standard.read(service: "access-id", account: "cronicaTMDB-Sync")
        let session = KeychainHelper.standard.read(service: "session-id", account: "cronicaTMDB-Sync")
        guard let data else { return }
        let accessToken = String(data: data, encoding: .utf8)
        guard let accessToken else { return }
        userAccessToken = accessToken
        guard let IdData else { return }
        let accessId = String(data: IdData, encoding: .utf8)
        guard let accessId else { return }
        userAccessId = accessId
        guard let session else { return }
        let sessionId = String(data: session, encoding: .utf8)
        guard let sessionId else { return }
        userSessionId = sessionId
    }
    
    // MARK: Watchlist
    func fetchWatchlist(type: MediaType, page: Int) async -> TMDBWatchlist? {
        do {
            let headers = [
                "content-type": contentTypeHeader,
                "authorization": "Bearer \(userAccessToken)"
            ]
            guard let watchlistUrl = URL(string: "https://api.themoviedb.org/4/account/\(userAccessId)/\(type.rawValue)/watchlist?page=\(page)&sort_by=created_at.asc") else { return nil }
            var request = URLRequest(url: watchlistUrl,
                                     cachePolicy: .useProtocolCachePolicy,
                                     timeoutInterval: 10.0)
            request.httpMethod = "GET"
            request.allHTTPHeaderFields = headers
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let content =  try decoder.decode(TMDBWatchlist.self, from: data)
            return content
        } catch {
            return nil
        }
    }
    
    func updateWatchlist(with items: Data) async {
        do {
            let headers = [
                "content-type": contentTypeHeader
            ]
            guard let url = URL(string: "https://api.themoviedb.org/3/account/\(userAccessId)/watchlist?api_key=\(Key.tmdbApi)&session_id=\(userSessionId)") else { return }
            var request = URLRequest(url: url,
                                     cachePolicy: .useProtocolCachePolicy,
                                     timeoutInterval: 10.0)
            request.httpMethod = "POST"
            request.allHTTPHeaderFields = headers
            request.httpBody = items
            
            let (_, _) = try await URLSession.shared.data(for: request)
        } catch {
            if Task.isCancelled { return }
        }
    }
    
    // MARK: Lists
    func updateList(_ id: TMDBListResult.ID, with items: Data) async {
        do {
            let headers = [
                "authorization": "Bearer \(userAccessToken)",
                "content-type": contentTypeHeader
            ]
            guard let url = URL(string: "https://api.themoviedb.org/4/list/\(id)/items") else { return }
            var request = URLRequest(url: url,
                                     cachePolicy: .useProtocolCachePolicy,
                                     timeoutInterval: 10.0)
            request.httpMethod = "POST"
            request.allHTTPHeaderFields = headers
            request.httpBody = items
            
            let (_, _) = try await URLSession.shared.data(for: request)
        } catch {
            if Task.isCancelled { return }
        }
    }
    
    func removeItemFromList(_ id: TMDBListResult.ID, with items: Data) async {
        do {
            let headers = [
                "authorization": "Bearer \(userAccessToken)",
                "content-type": contentTypeHeader
            ]
            guard let url = URL(string: "https://api.themoviedb.org/4/list/\(id)/items") else { return }
            var request = URLRequest(url: url,
                                     cachePolicy: .useProtocolCachePolicy,
                                     timeoutInterval: 10.0)
            request.httpMethod = "DELETE"
            request.allHTTPHeaderFields = headers
            request.httpBody = items
            
            let (_, _) = try await URLSession.shared.data(for: request)
        } catch {
            if Task.isCancelled { return }
        }
    }
    
    // https://developer.themoviedb.org/v4/reference/list-item-status
    func checkItemStatusOnList(_ id: TMDBListResult.ID, itemID: Int, itemMedia: MediaType) async -> Bool {
        do {
            let headers = [
                "content-type": contentTypeHeader,
                "authorization": "Bearer \(userAccessToken)"
            ]
            guard let url = URL(string: "https://api.themoviedb.org/4/list/\(id)/item_status?media_id=\(itemID)&media_type=\(itemMedia.rawValue)") else { return false }
            var request = URLRequest(url: url,
                                     cachePolicy: .useProtocolCachePolicy,
                                     timeoutInterval: 10.0)
            request.httpMethod = "GET"
            request.allHTTPHeaderFields = headers
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let content =  try decoder.decode(TMDBItemStatus.self, from: data)
            let result = content.success ?? false
            return result
        } catch {
            return false
        }
    }
    
    
    /// Deletes a given list on TMDb.
    ///
    /// More details at: https://developers.themoviedb.org/4/list/delete-list
    /// - Parameter id: The ID of the list that will be deleted.
    /// - Returns: Boolean if the list was successfully or not deleted.
    func deleteList(_ id: Int) async -> Bool {
        do {
            let headers = [
                "content-type": contentTypeHeader,
                "authorization": "Bearer \(userAccessToken)"
            ]
            guard let url = URL(string: "https://api.themoviedb.org/4/list/\(id)") else { return false }
            var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
            request.httpMethod = "DELETE"
            request.allHTTPHeaderFields = headers
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let content =  try decoder.decode(GenericNetworkResponse.self, from: data)
            guard let success = content.success else { return false }
            return success
        } catch {
            return false
        }
    }
    
    /// Create a new list on TMDb.
    ///
    /// More details at: https://developers.themoviedb.org/4/list/create-list
    /// - Parameters:
    ///   - list: The list title and list description will be used to create the new list.
    ///   - isPublic: Define the privacy level of the list, it is private by default.
    /// - Returns: If the list is successfully created, it will return the new list ID of the newly created list.
    func publishList(title: String, description: String) async -> Int? {
        do {
            let headers = [
                "authorization": "Bearer \(userAccessToken)",
                "content-type": contentTypeHeader
            ]
            let parameters = [
                "name": "\(title)",
                "description": description,
                "iso_639_1": "en",
                "public": "false"
            ]
            guard let url = URL(string: "https://api.themoviedb.org/4/list") else { return nil }
            let postData = try JSONSerialization.data(withJSONObject: parameters)
            var request = URLRequest(url: url,
                                     cachePolicy: .useProtocolCachePolicy,
                                     timeoutInterval: 10.0)
            request.httpMethod = "POST"
            request.allHTTPHeaderFields = headers
            request.httpBody = postData
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let content =  try decoder.decode(TMDBNewList.self, from: data)
            return content.id
        } catch {
            return nil
        }
    }
    
    func fetchLists() async -> TMDBList? {
        do {
            let headers = [
                "content-type": contentTypeHeader,
                "authorization": "Bearer \(userAccessToken)"
            ]
            guard let url = URL(string: "https://api.themoviedb.org/4/account/\(userAccessId)/lists") else { return nil }
            var request = URLRequest(url: url,
                                     cachePolicy: .useProtocolCachePolicy,
                                     timeoutInterval: 10.0)
            request.httpMethod = "GET"
            request.allHTTPHeaderFields = headers
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let content =  try decoder.decode(TMDBList.self, from: data)
            return content
        } catch {
            return nil
        }
    }
    
    func fetchListDetails(for id: TMDBListResult.ID, page: Int) async -> DetailedTMDBList? {
        do {
            let headers = [
                "content-type": contentTypeHeader,
                "authorization": "Bearer \(userAccessToken)"
            ]
            guard let url = URL(string: "https://api.themoviedb.org/4/list/\(id)?page=\(page)") else { return nil }
            var request = URLRequest(url: url,
                                     cachePolicy: .useProtocolCachePolicy,
                                     timeoutInterval: 10.0)
            request.httpMethod = "GET"
            request.allHTTPHeaderFields = headers
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let content =  try decoder.decode(DetailedTMDBList.self, from: data)
            return content
        } catch {
            return nil
        }
    }
}

struct GenericNetworkResponse: Codable {
    var statusMessage: String?
    var success: Bool?
    var statusCode: Int?
}
