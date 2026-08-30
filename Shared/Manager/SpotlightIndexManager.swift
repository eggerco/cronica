//
//  SpotlightIndexManager.swift
//  Cronica
//

#if canImport(CoreSpotlight) && !os(watchOS) && !os(tvOS)
import CoreData
@preconcurrency import CoreSpotlight
import CronicaCore

enum SpotlightIndexManager {
    static let domainIdentifier = "dev.alexandremadeira.cronica.watchlist"
    private static let lastFullRebuildKey = "spotlight.lastFullRebuild"
    private static let fullRebuildInterval: TimeInterval = 86_400

    @MainActor
    static func indexWatchlistItem(_ item: WatchlistItem) {
        guard !item.isArchive else {
            removeWatchlistItem(contentID: item.itemContentID)
            return
        }
        let searchable = searchableItem(for: item)
        Task { @MainActor in
            do {
                try await CSSearchableIndex.default().indexSearchableItems([searchable])
            } catch {
                AppLogger.persistence.error("Spotlight index failed: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    static func removeWatchlistItem(contentID: String) {
        Task { @MainActor in
            do {
                try await CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [contentID])
            } catch {
                AppLogger.persistence.error("Spotlight remove failed: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    static func rebuildIndexIfNeeded(force: Bool = false) {
        let lastRebuild = UserDefaults.standard.object(forKey: lastFullRebuildKey) as? Date ?? .distantPast
        guard force || Date().timeIntervalSince(lastRebuild) > fullRebuildInterval else { return }

        let context = PersistenceController.shared.container.viewContext
        let request = WatchlistItem.fetchRequest()
        request.predicate = NSPredicate(format: "isArchive == NO")
        let items = (try? context.fetch(request)) ?? []
        // CoreSpotlight types are not Sendable; keep indexing on the MainActor via async APIs.
        nonisolated(unsafe) let searchableItems = items.map(searchableItem(for:))

        Task { @MainActor in
            do {
                try await CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [domainIdentifier])
                try await CSSearchableIndex.default().indexSearchableItems(searchableItems)
                UserDefaults.standard.set(Date(), forKey: lastFullRebuildKey)
            } catch {
                AppLogger.persistence.error("Spotlight rebuild failed: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    static func clearAll() {
        Task { @MainActor in
            do {
                try await CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [domainIdentifier])
            } catch {
                AppLogger.persistence.error("Spotlight clear failed: \(error.localizedDescription)")
            }
            UserDefaults.standard.removeObject(forKey: lastFullRebuildKey)
        }
    }

    static func contentID(from userActivity: NSUserActivity) -> String? {
        guard userActivity.activityType == CSSearchableItemActionType,
              let identifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String
        else { return nil }
        return identifier
    }

    @MainActor
    private static func searchableItem(for item: WatchlistItem) -> CSSearchableItem {
        let attributes = CSSearchableItemAttributeSet(contentType: .content)
        attributes.title = item.itemTitle
        attributes.contentDescription = item.itemGlanceInfo
        attributes.keywords = [item.itemTitle, "Cronica", "watchlist"]
        attributes.relatedUniqueIdentifier = item.itemContentID

        let searchableItem = CSSearchableItem(
            uniqueIdentifier: item.itemContentID,
            domainIdentifier: domainIdentifier,
            attributeSet: attributes
        )
        searchableItem.expirationDate = Calendar.current.date(byAdding: .year, value: 1, to: .now)
        return searchableItem
    }
}
#endif

enum SpotlightRefreshBridge {
    static func refreshIfAvailable() {
#if canImport(CoreSpotlight) && !os(watchOS) && !os(tvOS)
        Task { @MainActor in
            SpotlightIndexManager.rebuildIndexIfNeeded()
        }
#endif
    }

    static func indexIfAvailable(_ item: WatchlistItem) {
#if canImport(CoreSpotlight) && !os(watchOS) && !os(tvOS)
        Task { @MainActor in
            SpotlightIndexManager.indexWatchlistItem(item)
        }
#endif
    }

    static func removeIfAvailable(contentID: String) {
#if canImport(CoreSpotlight) && !os(watchOS) && !os(tvOS)
        Task { @MainActor in
            SpotlightIndexManager.removeWatchlistItem(contentID: contentID)
        }
#endif
    }

    static func clearIfAvailable() {
#if canImport(CoreSpotlight) && !os(watchOS) && !os(tvOS)
        Task { @MainActor in
            SpotlightIndexManager.clearAll()
        }
#endif
    }
}
