//
//  OMDbAPIClient.swift
//  Cronica
//

import CronicaCore
import Foundation

actor OMDbAPIClient {
    static let shared = OMDbAPIClient()

    private let session: URLSession

    private init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchRatings(imdbId: String) async throws -> (rottenTomatoes: String?, metacritic: String?) {
        guard Key.isOMDbConfigured else { throw CriticRatingsError.notConfigured }
        var components = URLComponents(string: "https://www.omdbapi.com/")!
        components.queryItems = [
            URLQueryItem(name: "i", value: imdbId),
            URLQueryItem(name: "apikey", value: Key.omdbApiKey)
        ]
        guard let url = components.url else { throw CriticRatingsError.invalidResponse }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw CriticRatingsError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(OMDbRatingResponse.self, from: data)
        guard decoded.isSuccessful else { return (nil, nil) }
        return (decoded.rottenTomatoesScore, decoded.metacriticScore)
    }
}
