//
//  UpNextMarkActionRunner.swift
//  Cronica
//

import CoreData
import CronicaCore
#if os(iOS)
import WidgetKit
#endif

@MainActor
enum UpNextMarkActionRunner {
    enum RunnerError: LocalizedError {
        case noUpNext

        var errorDescription: String? {
            switch self {
            case .noUpNext:
                return String(localized: "You don't have any episodes up next.")
            }
        }
    }

    struct Summary: Sendable {
        let showTitle: String
        let seasonNumber: Int
        let episodeNumber: Int
        let episodeName: String?
        let contentID: String
    }

    private struct ResolvedEpisode {
        let summary: Summary
        let episode: Episode
    }

    private static let persistence = PersistenceController.shared
    private static let network = NetworkService.shared

    static func markNextEpisodeWatched() async throws -> String {
        guard let resolved = try await resolveUpNextEpisodes(limit: 1).first else {
            throw RunnerError.noUpNext
        }

        let summary = resolved.summary
        guard let item = persistence.fetch(for: summary.contentID) else {
            throw RunnerError.noUpNext
        }

        let showID = item.itemId
        let episode = resolved.episode

        persistence.updateWatchedEpisodes(for: item, with: episode)
        let helper = EpisodeHelper()
        if let nextEpisode = await helper.fetchNextEpisode(for: episode, show: showID) {
            persistence.updateUpNext(item, episode: nextEpisode)
        }

        refreshSurfacesAfterMark()

        let episodeLabel = summary.episodeName ?? String(
            format: String(localized: "S%d · E%d"),
            summary.seasonNumber,
            summary.episodeNumber
        )
        return "\(summary.showTitle) — \(episodeLabel)"
    }

    static func firstUpNextSummary() async throws -> Summary? {
        try await upNextSummaries(limit: 1).first
    }

    static func upNextSummaries(limit: Int = 5) async throws -> [Summary] {
        try await resolveUpNextEpisodes(limit: limit).map(\.summary)
    }

    private static func resolveUpNextEpisodes(limit: Int) async throws -> [ResolvedEpisode] {
        var episodes: [ResolvedEpisode] = []
        let items = persistence.fetchUpNextWatchlistItems()
        for item in items where episodes.count < limit {
            guard let resolved = await resolveUpNextEpisode(for: item) else { continue }
            episodes.append(resolved)
        }
        if episodes.isEmpty {
            throw RunnerError.noUpNext
        }
        return episodes
    }

    private static func resolveUpNextEpisode(for item: WatchlistItem) async -> ResolvedEpisode? {
        let result = try? await network.fetchEpisode(
            tvID: Int64(item.itemId),
            season: item.itemNextUpNextSeason,
            episodeNumber: item.itemNextUpNextEpisode
        )
        guard let result else { return nil }
        let seasonNumber = result.seasonNumber ?? Int(item.itemNextUpNextSeason)
        let episodeNumber = result.episodeNumber ?? Int(item.itemNextUpNextEpisode)
        let summary = Summary(
            showTitle: item.itemTitle,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber,
            episodeName: result.name,
            contentID: item.itemContentID
        )
        return ResolvedEpisode(summary: summary, episode: result)
    }

    private static func refreshSurfacesAfterMark() {
        WidgetSnapshotPublisherBridge.scheduleRefreshIfAvailable()
#if os(iOS) && !CRONICA_WIDGET_EXTENSION && !CRONICA_SHARE_EXTENSION
        QuickActionRefreshBridge.refreshIfAvailable()
#endif
#if os(iOS)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.upNext)
#endif
    }
}
