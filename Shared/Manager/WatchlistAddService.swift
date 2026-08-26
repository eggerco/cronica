//
//  WatchlistAddService.swift
//  Cronica
//

import Foundation
import CronicaCore
#if canImport(WidgetKit)
import WidgetKit
#endif

enum WatchlistAddService {
    enum AddResult: Equatable {
        case added(ItemContent)
        case alreadyOnWatchlist
        case unsupportedURL
        case notFound
        case fetchFailed
    }

    @MainActor
    static func add(from url: URL, persistence: PersistenceController = .shared) async -> AddResult {
        guard let hint = MediaURLResolver.parse(url) else {
            return .unsupportedURL
        }

        do {
            guard let reference = try await NetworkService.shared.resolveContentReference(from: hint) else {
                return .notFound
            }
            return await add(reference: reference, persistence: persistence)
        } catch {
            return .fetchFailed
        }
    }

    @MainActor
    static func add(contentID: String, persistence: PersistenceController = .shared) async -> AddResult {
        guard let reference = TMDBURLParser.parseContentID(contentID) else {
            return .unsupportedURL
        }
        return await add(reference: reference, persistence: persistence)
    }

    @MainActor
    static func add(reference: TMDBURLParser.ContentReference,
                    persistence: PersistenceController = .shared) async -> AddResult {
        if persistence.isItemSaved(id: reference.contentID) {
            return .alreadyOnWatchlist
        }

        guard let content = try? await NetworkService.shared.fetchItem(id: reference.id, type: reference.type) else {
            return .fetchFailed
        }

        persistence.save(content)

        if content.itemContentMedia == .tvShow {
            await addFirstEpisodeToUpNext(content, persistence: persistence)
        }

#if CRONICA_SHARE_EXTENSION
        // Snapshot JSON is published by the main app; reload so Lock Screen /
        // Home widgets pick up updates as soon as the host app refreshes them.
        WidgetCenter.shared.reloadAllTimelines()
#else
        WidgetSnapshotPublisherBridge.scheduleRefreshIfAvailable()
#endif
        return .added(content)
    }

    @MainActor
    private static func addFirstEpisodeToUpNext(_ item: ItemContent,
                                                persistence: PersistenceController) async {
        let firstSeason = try? await NetworkService.shared.fetchSeason(id: item.id, season: 1)
        guard let firstEpisode = firstSeason?.episodes?.first,
              let savedItem = persistence.fetch(for: item.itemContentID)
        else { return }

        persistence.updateUpNext(savedItem, episode: firstEpisode)
    }
}
