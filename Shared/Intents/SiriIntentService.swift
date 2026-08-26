//
//  SiriIntentService.swift
//  Cronica
//

import Foundation
import CoreData
import CronicaCore

#if canImport(AppIntents) && !os(watchOS) && !os(tvOS)
import AppIntents

@MainActor
enum SiriIntentService {
    enum ServiceError: LocalizedError {
        case titleRequired
        case titleNotFound
        case notOnWatchlist
        case alreadyOnWatchlist
        case notReleased
        case noUpNext
        case networkFailure

        var errorDescription: String? {
            switch self {
            case .titleRequired:
                return String(localized: "Please say which title you mean.")
            case .titleNotFound:
                return String(localized: "Cronica couldn't find that movie or TV show.")
            case .notOnWatchlist:
                return String(localized: "That title isn't on your watchlist.")
            case .alreadyOnWatchlist:
                return String(localized: "That title is already on your watchlist.")
            case .notReleased:
                return String(localized: "That title hasn't been released yet.")
            case .noUpNext:
                return String(localized: "You don't have any episodes up next.")
            case .networkFailure:
                return String(localized: "Cronica couldn't reach TMDb. Try again in a moment.")
            }
        }
    }

    struct UpNextSummary: Sendable {
        let showTitle: String
        let seasonNumber: Int
        let episodeNumber: Int
        let episodeName: String?
        let contentID: String
    }

    struct SearchSummary: Sendable, Identifiable {
        let id: String
        let title: String
        let subtitle: String
        let mediaType: MediaType
    }

    private static let persistence = PersistenceController.shared
    private static let network = NetworkService.shared
    private static let notification = NotificationManager.shared

    static func addToWatchlist(title: String, mediaType: MediaType?) async throws -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ServiceError.titleRequired }

        guard let reference = try await network.resolveSearchTitle(trimmed, preferredType: mediaType) else {
            throw ServiceError.titleNotFound
        }

        switch await WatchlistAddService.add(reference: reference) {
        case .added(let content):
            scheduleSideEffects(for: content)
            return content.itemTitle
        case .alreadyOnWatchlist:
            throw ServiceError.alreadyOnWatchlist
        case .notFound:
            throw ServiceError.titleNotFound
        case .unsupportedURL, .fetchFailed:
            throw ServiceError.networkFailure
        }
    }

    static func removeFromWatchlist(title: String) async throws -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ServiceError.titleRequired }

        guard let item = persistence.bestMatchingWatchlistItem(for: trimmed) else {
            throw ServiceError.notOnWatchlist
        }

        let name = item.itemTitle
        notification.removeNotification(identifier: item.itemContentID)
        persistence.delete(item)
        WidgetSnapshotPublisherBridge.scheduleRefreshIfAvailable()
        return name
    }

    static func markTitleWatched(title: String) async throws -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ServiceError.titleRequired }

        let item: WatchlistItem
        if let watchlistItem = persistence.bestMatchingWatchlistItem(for: trimmed) {
            item = watchlistItem
        } else {
            guard let reference = try await network.resolveSearchTitle(trimmed, preferredType: nil),
                  let content = try? await network.fetchItem(id: reference.id, type: reference.type)
            else {
                throw ServiceError.titleNotFound
            }
            if !persistence.isItemSaved(id: content.itemContentID) {
                persistence.save(content)
                if content.itemContentMedia == .tvShow {
                    await addFirstEpisodeToUpNext(content)
                }
            }
            guard let saved = persistence.fetch(for: content.itemContentID) else {
                throw ServiceError.titleNotFound
            }
            item = saved
        }

        guard item.isReleasedForWatching else { throw ServiceError.notReleased }
        if !item.isWatched {
            persistence.updateWatched(for: item)
            if item.isTvShow {
                await markAllEpisodesWatched(for: item)
            }
        }
        WidgetSnapshotPublisherBridge.scheduleRefreshIfAvailable()
        return item.itemTitle
    }

    static func markNextUpNextEpisodeWatched() async throws -> String {
        guard let summary = try await firstUpNextSummary() else {
            throw ServiceError.noUpNext
        }

        guard let item = persistence.fetch(for: summary.contentID) else {
            throw ServiceError.noUpNext
        }

        let showID = item.itemId
        let episode = try await network.fetchEpisode(
            tvID: Int64(showID),
            season: Int64(summary.seasonNumber),
            episodeNumber: Int64(summary.episodeNumber)
        )

        persistence.updateWatchedEpisodes(for: item, with: episode)
        let helper = EpisodeHelper()
        if let nextEpisode = await helper.fetchNextEpisode(for: episode, show: showID) {
            persistence.updateUpNext(item, episode: nextEpisode)
        }
        WidgetSnapshotPublisherBridge.scheduleRefreshIfAvailable()

        let episodeLabel = summary.episodeName ?? String(
            format: String(localized: "S%d · E%d"),
            summary.seasonNumber,
            summary.episodeNumber
        )
        return "\(summary.showTitle) — \(episodeLabel)"
    }

    static func upNextSummaries(limit: Int = 5) async throws -> [UpNextSummary] {
        var summaries: [UpNextSummary] = []
        let items = persistence.fetchUpNextWatchlistItems()
        for item in items where summaries.count < limit {
            guard let summary = await upNextSummary(for: item) else { continue }
            summaries.append(summary)
        }
        if summaries.isEmpty {
            throw ServiceError.noUpNext
        }
        return summaries
    }

    static func searchTitles(query: String, limit: Int = 5) async throws -> [SearchSummary] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ServiceError.titleRequired }

        let results = try await network.search(query: trimmed, page: "1")
        let mapped = results.compactMap { result -> SearchSummary? in
            let mediaType = result.media
            guard mediaType != .person else { return nil }
            let title = result.itemTitle
            let contentID = "\(result.id)@\(mediaType.toInt)"
            let subtitle: String
            switch mediaType {
            case .movie:
                subtitle = String(localized: "Movie")
            case .tvShow:
                subtitle = String(localized: "TV Show")
            case .person:
                subtitle = String(localized: "Person")
            }
            return SearchSummary(id: contentID, title: title, subtitle: subtitle, mediaType: mediaType)
        }
        let limited = Array(mapped.prefix(limit))
        guard !limited.isEmpty else { throw ServiceError.titleNotFound }
        return limited
    }

    static func openURL(for title: String) async throws -> URL {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ServiceError.titleRequired }

        if let item = persistence.bestMatchingWatchlistItem(for: trimmed),
           let url = URL(string: "cronica://\(item.itemContentID)") {
            return url
        }

        guard let reference = try await network.resolveSearchTitle(trimmed, preferredType: nil) else {
            throw ServiceError.titleNotFound
        }
        guard let url = URL(string: "cronica://\(reference.contentID)") else {
            throw ServiceError.titleNotFound
        }
        return url
    }

    static func watchlistEntities(matching query: String) -> [WatchlistTitleEntity] {
        let items = persistence.fetchWatchlistItems(matching: query, limit: 12)
        return items.map(WatchlistTitleEntity.init(item:))
    }

    static func allWatchlistEntities(limit: Int = 12) -> [WatchlistTitleEntity] {
        let request: NSFetchRequest<WatchlistItem> = WatchlistItem.fetchRequest()
        request.fetchLimit = limit
        request.sortDescriptors = [NSSortDescriptor(key: "lastValuesUpdated", ascending: false)]
        let items = (try? persistence.container.viewContext.fetch(request)) ?? []
        return items.map(WatchlistTitleEntity.init(item:))
    }

    // MARK: - Private

    private static func firstUpNextSummary() async throws -> UpNextSummary? {
        try await upNextSummaries(limit: 1).first
    }

    private static func upNextSummary(for item: WatchlistItem) async -> UpNextSummary? {
        let result = try? await network.fetchEpisode(
            tvID: Int64(item.itemId),
            season: item.itemNextUpNextSeason,
            episodeNumber: item.itemNextUpNextEpisode
        )
        guard let result else { return nil }
        let seasonNumber = result.seasonNumber ?? Int(item.itemNextUpNextSeason)
        let episodeNumber = result.episodeNumber ?? Int(item.itemNextUpNextEpisode)
        return UpNextSummary(
            showTitle: item.itemTitle,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber,
            episodeName: result.name,
            contentID: item.itemContentID
        )
    }

    private static func scheduleSideEffects(for content: ItemContent) {
        if content.itemCanNotify && content.itemFallbackDate.isLessThanTwoWeeksAway() {
            notification.schedule(content)
        }
        CalendarManager.shared.schedule(content)
    }

    private static func addFirstEpisodeToUpNext(_ content: ItemContent) async {
        let firstSeason = try? await network.fetchSeason(id: content.id, season: 1)
        guard let firstEpisode = firstSeason?.episodes?.first,
              let savedItem = persistence.fetch(for: content.itemContentID)
        else { return }
        persistence.updateUpNext(savedItem, episode: firstEpisode)
    }

    private static func markAllEpisodesWatched(for item: WatchlistItem) async {
        guard let show = try? await network.fetchItem(id: item.itemId, type: .tvShow),
              let seasons = show.seasons
        else { return }

        var episodes: [Episode] = []
        for season in seasons {
            let result = try? await network.fetchSeason(id: item.itemId, season: season.seasonNumber)
            if let items = result?.episodes {
                episodes.append(contentsOf: items)
            }
        }
        if !episodes.isEmpty {
            persistence.updateEpisodeList(to: item, show: item.itemId, episodes: episodes)
        }
    }
}
#endif
