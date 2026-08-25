//
//  CriticRatingsModels.swift
//  Cronica
//

import Foundation

struct ExternalCriticRatings: Equatable {
    var tmdb: String?
    var rottenTomatoes: String?
    var metacritic: String?
    var letterboxd: String?

    var hasAnyScore: Bool {
        [tmdb, rottenTomatoes, metacritic, letterboxd].contains { value in
            guard let value, !value.isEmpty else { return false }
            return true
        }
    }
}

struct OMDbRatingResponse: Decodable {
    let response: String?
    let metascore: String?
    let ratings: [Entry]?

    struct Entry: Decodable {
        let source: String
        let value: String
    }

    var rottenTomatoesScore: String? {
        ratings?.first(where: { $0.source == "Rotten Tomatoes" })?.value
    }

    var metacriticScore: String? {
        if let metascore, !metascore.isEmpty, metascore != "N/A" {
            return metascore.contains("/") ? metascore : "\(metascore)/100"
        }
        if let value = ratings?.first(where: { $0.source == "Metacritic" })?.value {
            return value
        }
        return nil
    }

    var isSuccessful: Bool {
        response?.caseInsensitiveCompare("True") == .orderedSame
    }
}

enum CriticRatingsError: Error {
    case notConfigured
    case invalidResponse
    case missingIMDbID
}
