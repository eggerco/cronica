//
//  PersistentHistoryMerger.swift
//  Cronica
//

@preconcurrency import CoreData
import Foundation

#if os(iOS) && !CRONICA_SHARE_EXTENSION
/// Merges App Group store writes from the Share Extension into the main app's view context.
enum PersistentHistoryMerger {
    private static let lastTokenKey = "persistentHistory.lastToken"
    private static var observer: NSObjectProtocol?
    @MainActor private static var isMerging = false
    @MainActor private static var hasPendingMerge = false

    private struct HistoryChanges: Sendable {
        let inserted: [NSManagedObjectID]
        let updated: [NSManagedObjectID]
        let deleted: [NSManagedObjectID]

        init(userInfo: [AnyHashable: Any]) {
            inserted = Self.objectIDs(userInfo[NSInsertedObjectsKey] ?? userInfo[NSInsertedObjectIDsKey])
            updated = Self.objectIDs(userInfo[NSUpdatedObjectsKey] ?? userInfo[NSUpdatedObjectIDsKey])
            deleted = Self.objectIDs(userInfo[NSDeletedObjectsKey] ?? userInfo[NSDeletedObjectIDsKey])
        }

        var userInfo: [AnyHashable: Any] {
            [NSInsertedObjectsKey: inserted, NSUpdatedObjectsKey: updated, NSDeletedObjectsKey: deleted]
        }

        private static func objectIDs(_ value: Any?) -> [NSManagedObjectID] {
            if let ids = value as? [NSManagedObjectID] { return ids }
            return Array(value as? Set<NSManagedObjectID> ?? [])
        }
    }

    private struct HistoryFetchResult: Sendable {
        let changes: [HistoryChanges]
        let tokenData: Data?
    }

    static func startObserving(container: NSPersistentCloudKitContainer) {
        guard observer == nil else { return }
        observer = NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator,
            queue: .main
        ) { _ in
            Task { @MainActor in
                await merge(into: container)
            }
        }
        // Catch up on any writes that happened while the app was not running.
        Task { @MainActor in
            await merge(into: container)
        }
    }

    @MainActor
    static func merge(into container: NSPersistentCloudKitContainer) async {
        guard !isMerging else {
            hasPendingMerge = true
            return
        }
        isMerging = true
        defer { isMerging = false }

        repeat {
            hasPendingMerge = false
            let background = container.newBackgroundContext()
            do {
                let result = try await background.perform {
                    let request = NSPersistentHistoryChangeRequest.fetchHistory(after: loadToken())
                    guard let result = try background.execute(request) as? NSPersistentHistoryResult,
                          let transactions = result.result as? [NSPersistentHistoryTransaction],
                          let lastTransaction = transactions.last
                    else { return HistoryFetchResult(changes: [], tokenData: nil) }

                    let changes = transactions.compactMap { transaction in
                        transaction.objectIDNotification().userInfo.map(HistoryChanges.init(userInfo:))
                    }
                    let tokenData = try? NSKeyedArchiver.archivedData(
                        withRootObject: lastTransaction.token,
                        requiringSecureCoding: true
                    )
                    return HistoryFetchResult(changes: changes, tokenData: tokenData)
                }
                if !result.changes.isEmpty {
                    for changes in result.changes {
                        NSManagedObjectContext.mergeChanges(
                            fromRemoteContextSave: changes.userInfo,
                            into: [container.viewContext]
                        )
                    }
                    if let tokenData = result.tokenData {
                        UserDefaults.standard.set(tokenData, forKey: lastTokenKey)
                    }
                    WidgetSnapshotPublisherBridge.scheduleRefreshIfAvailable()
                }
            } catch {
                AppLogger.persistence.error(
                    "Persistent history merge failed: \(error.localizedDescription)"
                )
            }
            // Drain notifications received while the history fetch was suspended.
        } while hasPendingMerge
    }

    private static func loadToken() -> NSPersistentHistoryToken? {
        guard let data = UserDefaults.standard.data(forKey: lastTokenKey) else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(
            ofClass: NSPersistentHistoryToken.self,
            from: data
        )
    }
}
#endif
