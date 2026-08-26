//
//  WidgetSnapshotPublisher.swift
//  Cronica
//

import CoreData
import CronicaCore
import Foundation
#if os(iOS)
import UIKit
import WidgetKit

@MainActor
final class WidgetSnapshotPublisher {
    static let shared = WidgetSnapshotPublisher()

    private let persistence = PersistenceController.shared
    private let settings = SettingsStore.shared
    private var pendingTask: Task<Void, Never>?

    private init() {}

    func scheduleRefresh(after delay: TimeInterval = 0.35) {
        pendingTask?.cancel()
        pendingTask = Task { [weak self] in
            let nanoseconds = UInt64(max(delay, 0) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
            guard !Task.isCancelled else { return }
            await self?.publish()
        }
    }

    func publish() async {
        guard WidgetAppGroup.containerURL != nil else {
            AppLogger.persistence.warning("Widget app group container unavailable; skipping snapshot publish.")
            reloadWidgetTimelines()
            return
        }

        let context = persistence.container.viewContext
        let upNextItems = fetchUpNextItems(in: context)
        let watchlistItems = fetchWatchlistItems(in: context)

        let upNextSnapshotItems = await buildUpNextSnapshotItems(from: upNextItems)
        let watchlistSnapshotItems = await buildWatchlistSnapshotItems(from: watchlistItems)

        do {
            try WidgetSnapshotStore.writeUpNext(
                WidgetUpNextSnapshot(items: upNextSnapshotItems, updatedAt: .now)
            )
            try WidgetSnapshotStore.writeWatchlist(
                WidgetWatchlistSnapshot(items: watchlistSnapshotItems, updatedAt: .now)
            )
            let keptPosters = Set(
                (upNextSnapshotItems + watchlistSnapshotItems).compactMap(\.posterFileName)
            )
            WidgetSnapshotStore.pruneUnusedPosters(keeping: keptPosters)
        } catch {
            AppLogger.persistence.error("Failed to write widget snapshots: \(error.localizedDescription)")
        }

        reloadWidgetTimelines()
    }

    // MARK: - Fetch

    private func fetchUpNextItems(in context: NSManagedObjectContext) -> [WatchlistItem] {
        let request = WatchlistItem.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "displayOnUpNext == %d", true),
            NSPredicate(format: "hideFromUpNext == %d", false),
            NSPredicate(format: "isArchive == %d", false),
            NSPredicate(format: "watched == %d", false),
            NSPredicate(format: "contentType == %d", MediaType.tvShow.toInt)
        ])
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WatchlistItem.title, ascending: true)]
        let items = (try? context.fetch(request)) ?? []
        return sortUpNextItems(items.filter { $0.firstAirDate != nil })
    }

    private func fetchWatchlistItems(in context: NSManagedObjectContext) -> [WatchlistItem] {
        let request = WatchlistItem.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "isArchive == %d", false),
            NSPredicate(format: "watched == %d", false)
        ])
        let items = (try? context.fetch(request)) ?? []
        return items
            .filter { $0.isPin || $0.isCurrentlyWatching }
            .sorted { lhs, rhs in
                if lhs.isPin != rhs.isPin { return lhs.isPin && !rhs.isPin }
                return lhs.itemLastUpdateDate > rhs.itemLastUpdateDate
            }
            .prefix(WidgetSnapshotLayout.maxItems)
            .map { $0 }
    }

    private func sortUpNextItems(_ items: [WatchlistItem]) -> [WatchlistItem] {
        var filtered = items
        if settings.hideUnstartedUpNext {
            filtered = filtered.filter(\.hasStartedWatching)
        }

        switch settings.upNextSortOrder {
        case .recentActivity:
            return filtered.sorted { $0.itemLastUpdateDate > $1.itemLastUpdateDate }
        case .watchProgress:
            return filtered.sorted {
                if $0.watchProgress != $1.watchProgress {
                    return $0.watchProgress > $1.watchProgress
                }
                if $0.watchedEpisodeCount != $1.watchedEpisodeCount {
                    return $0.watchedEpisodeCount > $1.watchedEpisodeCount
                }
                return $0.itemLastUpdateDate > $1.itemLastUpdateDate
            }
        }
    }

    // MARK: - Build

    private func buildUpNextSnapshotItems(from items: [WatchlistItem]) async -> [WidgetSnapshotItem] {
        var results = [WidgetSnapshotItem]()
        for item in items.prefix(WidgetSnapshotLayout.maxItems) {
            let season = Int(item.itemNextUpNextSeason)
            let episode = Int(item.itemNextUpNextEpisode)
            let subtitle = String(format: String(localized: "S%d · E%d"), season, episode)
            let deepLink = "cronica://\(item.itemContentID)"
            let posterFileName = await cachePoster(for: item)
            results.append(
                WidgetSnapshotItem(
                    id: item.itemContentID,
                    title: item.itemTitle,
                    subtitle: subtitle,
                    deepLink: deepLink,
                    posterFileName: posterFileName,
                    watchProgress: item.watchProgress,
                    sortDate: item.itemLastUpdateDate
                )
            )
        }
        return results
    }

    private func buildWatchlistSnapshotItems(from items: [WatchlistItem]) async -> [WidgetSnapshotItem] {
        var results = [WidgetSnapshotItem]()
        for item in items {
            let subtitle = watchlistSubtitle(for: item)
            let deepLink = "cronica://\(item.itemContentID)"
            let posterFileName = await cachePoster(for: item)
            results.append(
                WidgetSnapshotItem(
                    id: item.itemContentID,
                    title: item.itemTitle,
                    subtitle: subtitle,
                    deepLink: deepLink,
                    posterFileName: posterFileName,
                    watchProgress: item.watchProgress,
                    sortDate: item.itemLastUpdateDate
                )
            )
        }
        return results
    }

    private func watchlistSubtitle(for item: WatchlistItem) -> String? {
        if item.isTvShow {
            if item.watchProgress > 0 {
                let percent = Int((item.watchProgress * 100).rounded())
                return String(format: String(localized: "%d%% watched"), percent)
            }
            if item.isCurrentlyWatching {
                return String(localized: "Watching")
            }
        }
        if item.isPin {
            return String(localized: "Pinned")
        }
        return nil
    }

    private func cachePoster(for item: WatchlistItem) async -> String? {
        let fileName = WidgetSnapshotStore.posterFileName(for: item.itemContentID)

        if WidgetSnapshotStore.readPoster(named: fileName) != nil {
            return fileName
        }

        guard let imageURL = item.backCompatiblePosterImage
                ?? item.itemPosterImageMedium
                ?? item.mediumPosterImage
                ?? item.itemImage
                ?? item.image else {
            return nil
        }

        guard let data = try? await NetworkService.shared.downloadData(from: imageURL),
              let jpeg = Self.jpegData(from: data) else {
            return nil
        }

        do {
            try WidgetSnapshotStore.writePoster(jpeg, fileName: fileName)
            return fileName
        } catch {
            AppLogger.persistence.debug("Widget poster cache failed for \(item.itemContentID): \(error.localizedDescription)")
            return nil
        }
    }

    private static func jpegData(from data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return data }
        return image.jpegData(compressionQuality: WidgetSnapshotLayout.posterJPEGQuality)
    }

    private func reloadWidgetTimelines() {
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.upNext)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.watchlist)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.trending)
    }
}
#endif
