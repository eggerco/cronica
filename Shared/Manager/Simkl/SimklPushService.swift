//
//  SimklPushService.swift
//  Cronica
//

import Foundation
import CronicaCore

/// Optional Cronica → SIMKL writes with an offline queue and rate-limit backoff.
@MainActor
final class SimklPushService {
    static let shared = SimklPushService()

    private let queueKey = "simklPushQueue"
    private var isFlushing = false

    private init() {}

    enum Operation: Codable, Equatable {
        case addToList(tmdb: Int, media: Int, status: String, imdb: String?)
        case history(tmdb: Int, media: Int, season: Int?, episode: Int?, imdb: String?)
        case removeHistory(tmdb: Int, media: Int, imdb: String?)
        case rating(tmdb: Int, media: Int, rating: Int, imdb: String?)
        case removeRating(tmdb: Int, media: Int, imdb: String?)
        case scrobbleStop(tmdb: Int, media: Int, imdb: String?)
    }

    func enqueueAdd(tmdb: Int, media: MediaType, status: SimklWatchStatus = .plantowatch, imdb: String?) {
        guard shouldEnqueue else { return }
        let statusValue: String = {
            if media == .movie, status == .watching || status == .hold {
                return SimklWatchStatus.plantowatch.rawValue
            }
            return status.rawValue
        }()
        append(.addToList(tmdb: tmdb, media: Int(media.toInt), status: statusValue, imdb: imdb))
        Task { await flush() }
    }

    func enqueueWatched(tmdb: Int, media: MediaType, imdb: String?) {
        guard shouldEnqueue else { return }
        if media == .movie {
            append(.history(tmdb: tmdb, media: Int(MediaType.movie.toInt), season: nil, episode: nil, imdb: imdb))
        } else {
            append(.addToList(tmdb: tmdb, media: Int(MediaType.tvShow.toInt), status: SimklWatchStatus.completed.rawValue, imdb: imdb))
        }
        Task { await flush() }
    }

    func enqueueEpisode(showID: Int, season: Int, episode: Int, imdb: String?) {
        guard shouldEnqueue else { return }
        append(.history(tmdb: showID, media: Int(MediaType.tvShow.toInt), season: season, episode: episode, imdb: imdb))
        Task { await flush() }
    }

    func enqueueRemove(tmdb: Int, media: MediaType, imdb: String?) {
        guard shouldEnqueue else { return }
        append(.removeHistory(tmdb: tmdb, media: Int(media.toInt), imdb: imdb))
        Task { await flush() }
    }

    func enqueueArchive(tmdb: Int, media: MediaType, imdb: String?) {
        guard shouldEnqueue else { return }
        append(.addToList(tmdb: tmdb, media: Int(media.toInt), status: SimklWatchStatus.dropped.rawValue, imdb: imdb))
        Task { await flush() }
    }

    func enqueueRating(tmdb: Int, media: MediaType, cronicaRating: Int, imdb: String?) {
        guard shouldEnqueue else { return }
        if cronicaRating <= 0 {
            append(.removeRating(tmdb: tmdb, media: Int(media.toInt), imdb: imdb))
        } else {
            let simkl = SimklImportMapper.simklRating(fromCronica: cronicaRating)
            append(.rating(tmdb: tmdb, media: Int(media.toInt), rating: simkl, imdb: imdb))
        }
        Task { await flush() }
    }

    /// Marks a title fully watched via scrobble/stop (progress 100). Complements history writes.
    func enqueueScrobbleStop(tmdb: Int, media: MediaType, imdb: String?) {
        guard shouldEnqueue else { return }
        append(.scrobbleStop(tmdb: tmdb, media: Int(media.toInt), imdb: imdb))
        Task { await flush() }
    }

    /// Convenience for call sites that still have a managed object on the main actor.
    func enqueueAdd(item: WatchlistItem, status: SimklWatchStatus = .plantowatch) {
        enqueueAdd(tmdb: item.itemId, media: item.itemMedia, status: status, imdb: item.imdbID)
    }

    func enqueueWatched(item: WatchlistItem) {
        enqueueWatched(tmdb: item.itemId, media: item.itemMedia, imdb: item.imdbID)
    }

    func enqueueRemove(item: WatchlistItem) {
        enqueueRemove(tmdb: item.itemId, media: item.itemMedia, imdb: item.imdbID)
    }

    func enqueueArchive(item: WatchlistItem) {
        enqueueArchive(tmdb: item.itemId, media: item.itemMedia, imdb: item.imdbID)
    }

    func clearQueue() {
        UserDefaults.standard.removeObject(forKey: queueKey)
    }

    func flush() async {
        guard !isFlushing else { return }
        guard SettingsStore.shared.simklPushEnabled, SimklTokenStore.hasToken else { return }
        isFlushing = true
        defer { isFlushing = false }

        let queue = loadQueue()
        guard !queue.isEmpty else { return }

        var batchAdd: [Operation] = []
        var batchHistory: [Operation] = []
        var batchRemove: [Operation] = []
        var batchRatings: [Operation] = []
        var batchRemoveRatings: [Operation] = []
        var batchScrobble: [Operation] = []

        for op in queue {
            switch op {
            case .addToList: batchAdd.append(op)
            case .history: batchHistory.append(op)
            case .removeHistory: batchRemove.append(op)
            case .rating: batchRatings.append(op)
            case .removeRating: batchRemoveRatings.append(op)
            case .scrobbleStop: batchScrobble.append(op)
            }
        }

        do {
            try await sendAdds(batchAdd)
            try await sendHistory(batchHistory)
            try await sendRemoves(batchRemove)
            try await sendRatings(batchRatings)
            try await sendRemoveRatings(batchRemoveRatings)
            try await sendScrobbles(batchScrobble)
            saveQueue([])
        } catch {
            if case SimklError.notAuthenticated = error {
                clearQueue()
            } else {
                saveQueue(queue)
            }
            AppLogger.network.error("SIMKL push flush failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Private

    private var shouldEnqueue: Bool {
        SettingsStore.shared.simklPushEnabled
            && SimklTokenStore.hasToken
            && !IntegrationRemoteApply.shouldSuppressOutboundPush
    }

    private func append(_ op: Operation) {
        var queue = loadQueue()
        if !queue.contains(op) {
            queue.append(op)
            saveQueue(queue)
        }
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

    private func sendAdds(_ ops: [Operation]) async throws {
        guard !ops.isEmpty else { return }
        var byStatus: [String: (movies: [SimklHistoryItem], shows: [SimklHistoryItem])] = [:]
        for op in ops {
            guard case let .addToList(tmdb, media, status, imdb) = op else { continue }
            var bucket = byStatus[status] ?? ([], [])
            let item = SimklHistoryItem(ids: SimklWriteIds(tmdb: tmdb, imdb: imdb), watchedAt: nil, seasons: nil)
            if media == Int(MediaType.movie.toInt) {
                bucket.movies.append(item)
            } else {
                bucket.shows.append(item)
            }
            byStatus[status] = bucket
        }
        for (status, bucket) in byStatus {
            try await SimklAPIClient.shared.addToList(
                SimklAddToListPayload(
                    to: status,
                    movies: bucket.movies.isEmpty ? nil : bucket.movies,
                    shows: bucket.shows.isEmpty ? nil : bucket.shows
                )
            )
        }
    }

    private func sendHistory(_ ops: [Operation]) async throws {
        guard !ops.isEmpty else { return }
        var movies: [SimklHistoryItem] = []
        var shows: [SimklHistoryItem] = []
        for op in ops {
            guard case let .history(tmdb, media, season, episode, imdb) = op else { continue }
            if media == Int(MediaType.movie.toInt) {
                movies.append(SimklHistoryItem(ids: SimklWriteIds(tmdb: tmdb, imdb: imdb), watchedAt: nil, seasons: nil))
            } else if let season, let episode {
                shows.append(
                    SimklHistoryItem(
                        ids: SimklWriteIds(tmdb: tmdb, imdb: imdb),
                        watchedAt: nil,
                        seasons: [SimklHistorySeason(number: season, episodes: [SimklHistoryEpisode(number: episode)])]
                    )
                )
            } else {
                shows.append(SimklHistoryItem(ids: SimklWriteIds(tmdb: tmdb, imdb: imdb), watchedAt: nil, seasons: nil))
            }
        }
        try await SimklAPIClient.shared.addHistory(
            SimklHistoryPayload(
                movies: movies.isEmpty ? nil : movies,
                shows: shows.isEmpty ? nil : shows
            )
        )
    }

    private func sendRemoves(_ ops: [Operation]) async throws {
        guard !ops.isEmpty else { return }
        var movies: [SimklHistoryItem] = []
        var shows: [SimklHistoryItem] = []
        for op in ops {
            guard case let .removeHistory(tmdb, media, imdb) = op else { continue }
            let item = SimklHistoryItem(ids: SimklWriteIds(tmdb: tmdb, imdb: imdb), watchedAt: nil, seasons: nil)
            if media == Int(MediaType.movie.toInt) {
                movies.append(item)
            } else {
                shows.append(item)
            }
        }
        try await SimklAPIClient.shared.removeHistory(
            SimklHistoryPayload(
                movies: movies.isEmpty ? nil : movies,
                shows: shows.isEmpty ? nil : shows
            )
        )
    }

    private func sendRatings(_ ops: [Operation]) async throws {
        guard !ops.isEmpty else { return }
        var movies: [SimklRatedItem] = []
        var shows: [SimklRatedItem] = []
        for op in ops {
            guard case let .rating(tmdb, media, rating, imdb) = op else { continue }
            let item = SimklRatedItem(rating: rating, ids: SimklWriteIds(tmdb: tmdb, imdb: imdb))
            if media == Int(MediaType.movie.toInt) {
                movies.append(item)
            } else {
                shows.append(item)
            }
        }
        try await SimklAPIClient.shared.addRatings(
            SimklRatingsPayload(
                movies: movies.isEmpty ? nil : movies,
                shows: shows.isEmpty ? nil : shows
            )
        )
    }

    private func sendRemoveRatings(_ ops: [Operation]) async throws {
        guard !ops.isEmpty else { return }
        var movies: [SimklRatedItem] = []
        var shows: [SimklRatedItem] = []
        for op in ops {
            guard case let .removeRating(tmdb, media, imdb) = op else { continue }
            let item = SimklRatedItem(rating: 0, ids: SimklWriteIds(tmdb: tmdb, imdb: imdb))
            if media == Int(MediaType.movie.toInt) {
                movies.append(item)
            } else {
                shows.append(item)
            }
        }
        try await SimklAPIClient.shared.removeRatings(
            SimklRatingsPayload(
                movies: movies.isEmpty ? nil : movies,
                shows: shows.isEmpty ? nil : shows
            )
        )
    }

    private func sendScrobbles(_ ops: [Operation]) async throws {
        for op in ops {
            guard case let .scrobbleStop(tmdb, media, imdb) = op else { continue }
            let ids = SimklWriteIds(tmdb: tmdb, imdb: imdb)
            let item = SimklHistoryItem(ids: ids, watchedAt: nil, seasons: nil)
            let payload: SimklScrobblePayload
            if media == Int(MediaType.movie.toInt) {
                payload = SimklScrobblePayload(movie: item, show: nil, progress: 100)
            } else {
                payload = SimklScrobblePayload(movie: nil, show: item, progress: 100)
            }
            try await SimklAPIClient.shared.scrobbleStop(payload)
        }
    }
}
