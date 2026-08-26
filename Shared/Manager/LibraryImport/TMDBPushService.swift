//
//  TMDBPushService.swift
//  Cronica
//

import Foundation
import CronicaCore

/// Optional Cronica → TMDB account writes with an offline queue.
///
/// TMDB exposes watchlist, favorites, and ratings only — no watched history or scrobble API.
@MainActor
final class TMDBPushService {
    static let shared = TMDBPushService()

    private let queueKey = "tmdbPushQueue"
    private var isFlushing = false

    private init() {}

    enum Operation: Codable, Equatable {
        case watchlist(tmdb: Int, media: Int, onList: Bool)
        case favorite(tmdb: Int, media: Int, isFavorite: Bool)
        case rating(tmdb: Int, media: Int, value: Double)
        case removeRating(tmdb: Int, media: Int)
    }

    func enqueueWatchlist(tmdb: Int, media: MediaType, onList: Bool) {
        guard shouldEnqueue else { return }
        append(.watchlist(tmdb: tmdb, media: Int(media.toInt), onList: onList))
        Task { await flush() }
    }

    func enqueueFavorite(tmdb: Int, media: MediaType, isFavorite: Bool) {
        guard shouldEnqueue else { return }
        append(.favorite(tmdb: tmdb, media: Int(media.toInt), isFavorite: isFavorite))
        Task { await flush() }
    }

    /// TMDB has no watched list; marking watched removes the title from the TMDB watchlist.
    func enqueueWatched(tmdb: Int, media: MediaType) {
        guard shouldEnqueue else { return }
        append(.watchlist(tmdb: tmdb, media: Int(media.toInt), onList: false))
        Task { await flush() }
    }

    func enqueueRating(tmdb: Int, media: MediaType, cronicaRating: Int) {
        guard shouldEnqueue else { return }
        if cronicaRating <= 0 {
            append(.removeRating(tmdb: tmdb, media: Int(media.toInt)))
        } else {
            let value = LibraryImportService.tenPointRating(fromCronica: cronicaRating)
            append(.rating(tmdb: tmdb, media: Int(media.toInt), value: value))
        }
        Task { await flush() }
    }

    func clearQueue() {
        UserDefaults.standard.removeObject(forKey: queueKey)
    }

    func flush() async {
        guard !isFlushing else { return }
        guard SettingsStore.shared.tmdbPushEnabled, TMDBSessionStore.hasSession else { return }
        isFlushing = true
        defer { isFlushing = false }

        let queue = loadQueue()
        guard !queue.isEmpty else { return }

        var index = 0
        while index < queue.count {
            let op = queue[index]
            do {
                try await send(op)
                index += 1
                // Soft pacing against TMDB write rate limits.
                try await Task.sleep(nanoseconds: 350_000_000)
            } catch {
                if case LibraryImportError.message(let text) = error,
                   text.contains("(401)") || text.contains("(403)") {
                    clearQueue()
                    TMDBAccountAuthService.shared.disconnect()
                    AppLogger.network.error("TMDB push auth failed; disconnected.")
                    return
                }
                saveQueue(Array(queue[index...]))
                AppLogger.network.error("TMDB push flush failed: \(error.localizedDescription, privacy: .public)")
                return
            }
        }
        saveQueue([])
    }

    // MARK: - Private

    private var shouldEnqueue: Bool {
        SettingsStore.shared.tmdbPushEnabled
            && TMDBSessionStore.hasSession
            && !IntegrationRemoteApply.shouldSuppressOutboundPush
    }

    private func append(_ op: Operation) {
        var queue = loadQueue()
        // Replace earlier ops targeting the same list/rating key so the latest wins.
        queue.removeAll { existing in
            switch (existing, op) {
            case let (.watchlist(a, am, _), .watchlist(b, bm, _)) where a == b && am == bm: true
            case let (.favorite(a, am, _), .favorite(b, bm, _)) where a == b && am == bm: true
            case let (.rating(a, am, _), .rating(b, bm, _)) where a == b && am == bm: true
            case let (.rating(a, am, _), .removeRating(b, bm)) where a == b && am == bm: true
            case let (.removeRating(a, am), .rating(b, bm, _)) where a == b && am == bm: true
            case let (.removeRating(a, am), .removeRating(b, bm)) where a == b && am == bm: true
            default: false
            }
        }
        queue.append(op)
        saveQueue(queue)
    }

    private func loadQueue() -> [Operation] {
        guard let data = UserDefaults.standard.data(forKey: queueKey) else { return [] }
        return (try? JSONDecoder().decode([Operation].self, from: data)) ?? []
    }

    private func saveQueue(_ queue: [Operation]) {
        if let data = try? JSONEncoder().encode(queue) {
            UserDefaults.standard.set(data, forKey: queueKey)
        }
    }

    private func send(_ op: Operation) async throws {
        switch op {
        case let .watchlist(tmdb, media, onList):
            try await TMDBAccountAPIClient.shared.setWatchlist(
                mediaType: mediaTypeString(media),
                mediaID: tmdb,
                watchlist: onList
            )
        case let .favorite(tmdb, media, isFavorite):
            try await TMDBAccountAPIClient.shared.setFavorite(
                mediaType: mediaTypeString(media),
                mediaID: tmdb,
                favorite: isFavorite
            )
        case let .rating(tmdb, media, value):
            try await TMDBAccountAPIClient.shared.setRating(
                mediaType: mediaTypeString(media),
                mediaID: tmdb,
                value: value
            )
        case let .removeRating(tmdb, media):
            try await TMDBAccountAPIClient.shared.deleteRating(
                mediaType: mediaTypeString(media),
                mediaID: tmdb
            )
        }
    }

    private func mediaTypeString(_ media: Int) -> String {
        media == Int(MediaType.tvShow.toInt) ? "tv" : "movie"
    }
}
