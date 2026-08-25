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
    }

    func enqueueAdd(item: WatchlistItem, status: SimklWatchStatus = .plantowatch) {
        guard shouldEnqueue else { return }
        let statusValue: String = {
            if item.itemMedia == .movie, status == .watching || status == .hold {
                return SimklWatchStatus.plantowatch.rawValue
            }
            return status.rawValue
        }()
        append(.addToList(tmdb: item.itemId, media: item.itemMedia.toInt, status: statusValue, imdb: item.imdbID))
        Task { await flush() }
    }

    func enqueueWatched(item: WatchlistItem) {
        guard shouldEnqueue else { return }
        if item.itemMedia == .movie {
            append(.history(tmdb: item.itemId, media: MediaType.movie.toInt, season: nil, episode: nil, imdb: item.imdbID))
        } else {
            append(.addToList(tmdb: item.itemId, media: MediaType.tvShow.toInt, status: SimklWatchStatus.completed.rawValue, imdb: item.imdbID))
        }
        Task { await flush() }
    }

    func enqueueEpisode(showID: Int, season: Int, episode: Int, imdb: String?) {
        guard shouldEnqueue else { return }
        append(.history(tmdb: showID, media: MediaType.tvShow.toInt, season: season, episode: episode, imdb: imdb))
        Task { await flush() }
    }

    func enqueueRemove(item: WatchlistItem) {
        guard shouldEnqueue else { return }
        append(.removeHistory(tmdb: item.itemId, media: item.itemMedia.toInt, imdb: item.imdbID))
        Task { await flush() }
    }

    func enqueueArchive(item: WatchlistItem) {
        guard shouldEnqueue else { return }
        append(.addToList(tmdb: item.itemId, media: item.itemMedia.toInt, status: SimklWatchStatus.dropped.rawValue, imdb: item.imdbID))
        Task { await flush() }
    }

    func clearQueue() {
        UserDefaults.standard.removeObject(forKey: queueKey)
    }

    func flush() async {
        guard !isFlushing else { return }
        guard SettingsStore.shared.simklPushEnabled, SimklTokenStore.hasToken else { return }
        isFlushing = true
        defer { isFlushing = false }

        var queue = loadQueue()
        guard !queue.isEmpty else { return }

        var remaining: [Operation] = []
        var batchAdd: [Operation] = []
        var batchHistory: [Operation] = []
        var batchRemove: [Operation] = []

        for op in queue {
            switch op {
            case .addToList: batchAdd.append(op)
            case .history: batchHistory.append(op)
            case .removeHistory: batchRemove.append(op)
            }
        }

        do {
            try await sendAdds(batchAdd)
            try await sendHistory(batchHistory)
            try await sendRemoves(batchRemove)
            saveQueue([])
        } catch {
            // Keep queue for next flush; avoid spinning forever on auth failure.
            if case SimklError.notAuthenticated = error {
                clearQueue()
            } else {
                remaining = queue
                saveQueue(remaining)
            }
            AppLogger.network.error("SIMKL push flush failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Private

    private var shouldEnqueue: Bool {
        SettingsStore.shared.simklPushEnabled
            && SimklTokenStore.hasToken
            && !SimklSyncService.isApplyingRemoteChanges
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
        // Group by status so each POST has one `to`.
        var byStatus: [String: (movies: [SimklHistoryItem], shows: [SimklHistoryItem])] = [:]
        for op in ops {
            guard case let .addToList(tmdb, media, status, imdb) = op else { continue }
            var bucket = byStatus[status] ?? ([], [])
            let item = SimklHistoryItem(ids: SimklWriteIds(tmdb: tmdb, imdb: imdb), watchedAt: nil, seasons: nil)
            if media == MediaType.movie.toInt {
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
            if media == MediaType.movie.toInt {
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
            if media == MediaType.movie.toInt {
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
}
