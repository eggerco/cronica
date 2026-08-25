//
//  CriticRatingsService.swift
//  Cronica
//

import CronicaCore
import Foundation

actor CriticRatingsService {
    static let shared = CriticRatingsService()

    private let network = NetworkService.shared

    func fetch(for content: ItemContent, type: MediaType) async -> ExternalCriticRatings {
        var ratings = ExternalCriticRatings(tmdb: content.itemRating)

        guard let imdbId = await resolveIMDbID(for: content, type: type) else {
            return ratings
        }

        if Key.isOMDbConfigured {
            if let omdb = try? await OMDbAPIClient.shared.fetchRatings(imdbId: imdbId) {
                ratings.rottenTomatoes = omdb.rottenTomatoes
                ratings.metacritic = omdb.metacritic
            }
        }

        if type == .movie, let letterboxd = try? await LetterboxdRatingService.shared.fetchRating(imdbId: imdbId) {
            ratings.letterboxd = letterboxd
        }

        return ratings
    }

    private func resolveIMDbID(for content: ItemContent, type: MediaType) async -> String? {
        if let imdbId = content.imdbId, !imdbId.isEmpty {
            return imdbId
        }
        if let external = try? await network.fetchExternalIds(id: content.id, type: type),
           let imdbId = external.imdbId,
           !imdbId.isEmpty {
            return imdbId
        }
        return nil
    }
}
