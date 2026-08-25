//
//  TMDBAccountListCache.swift
//  Cronica
//

import Foundation
import CronicaCore

/// Conditional-request + fingerprint helpers for TMDB account lists.
///
/// TMDB has no activities feed. We still GET lists (or honor 304 via ETag when
/// present), then skip Core Data / catalog re-apply when the aggregate
/// fingerprint matches the last successful sync.
enum TMDBAccountListCache {
    static let fingerprintKey = "tmdbAccountListFingerprint"
    private static let etagPrefix = "tmdbAccountListETag."
    private static let bodyPrefix = "tmdbAccountListBody."

    // MARK: - Fingerprint

    /// Stable hash of watchlist / rated / favorite id sets (ratings included).
    nonisolated static func fingerprint(
        watchlistMovies: [TMDBAccountAPIClient.AccountMediaItem],
        watchlistTV: [TMDBAccountAPIClient.AccountMediaItem],
        ratedMovies: [TMDBAccountAPIClient.AccountMediaItem],
        ratedTV: [TMDBAccountAPIClient.AccountMediaItem],
        favoriteMovies: [TMDBAccountAPIClient.AccountMediaItem],
        favoriteTV: [TMDBAccountAPIClient.AccountMediaItem]
    ) -> String {
        let parts = [
            encode(list: "wl.m", items: watchlistMovies, includeRating: false),
            encode(list: "wl.tv", items: watchlistTV, includeRating: false),
            encode(list: "rt.m", items: ratedMovies, includeRating: true),
            encode(list: "rt.tv", items: ratedTV, includeRating: true),
            encode(list: "fv.m", items: favoriteMovies, includeRating: false),
            encode(list: "fv.tv", items: favoriteTV, includeRating: false)
        ]
        return parts.joined(separator: "|")
    }

    static func loadFingerprint() -> String? {
        let value = UserDefaults.standard.string(forKey: fingerprintKey)
        guard let value, !value.isEmpty else { return nil }
        return value
    }

    static func saveFingerprint(_ value: String) {
        UserDefaults.standard.set(value, forKey: fingerprintKey)
    }

    // MARK: - Per-page ETag / body

    static func etagKey(path: String, page: Int) -> String {
        "\(etagPrefix)\(path).p\(page)"
    }

    static func bodyKey(path: String, page: Int) -> String {
        "\(bodyPrefix)\(path).p\(page)"
    }

    static func loadETag(path: String, page: Int) -> String? {
        UserDefaults.standard.string(forKey: etagKey(path: path, page: page))
    }

    static func saveETag(_ etag: String, path: String, page: Int) {
        UserDefaults.standard.set(etag, forKey: etagKey(path: path, page: page))
    }

    static func loadBody(path: String, page: Int) -> Data? {
        UserDefaults.standard.data(forKey: bodyKey(path: path, page: page))
    }

    static func saveBody(_ data: Data, path: String, page: Int) {
        UserDefaults.standard.set(data, forKey: bodyKey(path: path, page: page))
    }

    static func clear() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: fingerprintKey)
        let keys = defaults.dictionaryRepresentation().keys.filter {
            $0.hasPrefix(etagPrefix) || $0.hasPrefix(bodyPrefix)
        }
        for key in keys {
            defaults.removeObject(forKey: key)
        }
    }

    // MARK: - Private

    private nonisolated static func encode(
        list: String,
        items: [TMDBAccountAPIClient.AccountMediaItem],
        includeRating: Bool
    ) -> String {
        let tokens = items
            .map { item -> String in
                if includeRating, let rating = item.rating {
                    return "\(item.id):\(rating)"
                }
                return "\(item.id)"
            }
            .sorted()
        return "\(list)=\(tokens.joined(separator: ","))"
    }
}
