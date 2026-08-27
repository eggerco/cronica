//
//  SpotlightIndexManager.swift
//  Cronica
//

#if canImport(CoreSpotlight) && !os(watchOS) && !os(tvOS)
import CoreData
import CoreSpotlight
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
        CSSearchableIndex.default().indexSearchableItems([searchableItem(for: item)]) { error in
            if let error {
                AppLogger.persistence.error("Spotlight index failed: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    static func removeWatchlistItem(contentID: String) {
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [contentID]) { error in
            if let error {
                AppLogger.persistence.error("Spotlight remove failed: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    static func rebuildIndexIfNeeded(force: Bool = false) {
        let defaults = UserDefaults.standard
        let lastRebuild = defaults.object(forKey: lastFullRebuildKey) as? Date ?? .distantPast
        guard force || Date().timeIntervalSince(lastRebuild) > fullRebuildInterval else { return }

        let context = PersistenceController.shared.container.viewContext
        let request = WatchlistItem.fetchRequest()
        request.predicate = NSPredicate(format: "isArchive == NO")
        let items = (try? context.fetch(request)) ?? []
        let searchableItems = items.map(searchableItem(for:))

        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [domainIdentifier]) { _ in
            CSSearchableIndex.default().indexSearchableItems(searchableItems) { error in
                if let error {
                    AppLogger.persistence.error("Spotlight rebuild failed: \(error.localizedDescription)")
                } else {
                    defaults.set(Date(), forKey: lastFullRebuildKey)
                }
            }
        }
    }

    @MainActor
    static func clearAll() {
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [domainIdentifier]) { _ in }
        UserDefaults.standard.removeObject(forKey: lastFullRebuildKey)
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
