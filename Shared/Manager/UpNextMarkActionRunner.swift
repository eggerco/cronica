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

    private static let persistence = PersistenceController.shared
    private static let network = NetworkService.shared

    static func markNextEpisodeWatched() async throws -> String {
        guard let summary = try await firstUpNextSummary() else {
            throw RunnerError.noUpNext
        }

        guard let item = persistence.fetch(for: summary.contentID) else {
            throw RunnerError.noUpNext
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
        var summaries: [Summary] = []
        let items = persistence.fetchUpNextWatchlistItems()
        for item in items where summaries.count < limit {
            guard let summary = await upNextSummary(for: item) else { continue }
            summaries.append(summary)
        }
        if summaries.isEmpty {
            throw RunnerError.noUpNext
        }
        return summaries
    }

    private static func upNextSummary(for item: WatchlistItem) async -> Summary? {
        let result = try? await network.fetchEpisode(
            tvID: Int64(item.itemId),
            season: item.itemNextUpNextSeason,
            episodeNumber: item.itemNextUpNextEpisode
        )
        guard let result else { return nil }
        let seasonNumber = result.seasonNumber ?? Int(item.itemNextUpNextSeason)
        let episodeNumber = result.episodeNumber ?? Int(item.itemNextUpNextEpisode)
        return Summary(
            showTitle: item.itemTitle,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber,
            episodeName: result.name,
            contentID: item.itemContentID
        )
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
