//
//  PersistentHistoryMerger.swift
//  Cronica
//

import CoreData
import Foundation

#if os(iOS) && !CRONICA_SHARE_EXTENSION
/// Merges App Group store writes from the Share Extension into the main app's view context.
enum PersistentHistoryMerger {
    private static let lastTokenKey = "persistentHistory.lastToken"
    private static var observer: NSObjectProtocol?
    private static var isMerging = false

    static func startObserving(container: NSPersistentCloudKitContainer) {
        guard observer == nil else { return }
        observer = NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator,
            queue: .main
        ) { _ in
            Task { @MainActor in
                merge(into: container)
            }
        }
        // Catch up on any writes that happened while the app was not running.
        Task { @MainActor in
            merge(into: container)
        }
    }

    @MainActor
    static func merge(into container: NSPersistentCloudKitContainer) {
        guard !isMerging else { return }
        isMerging = true
        defer { isMerging = false }

        let background = container.newBackgroundContext()
        background.performAndWait {
            do {
                let token = loadToken()
                let request = NSPersistentHistoryChangeRequest.fetchHistory(after: token)
                guard let result = try background.execute(request) as? NSPersistentHistoryResult,
                      let transactions = result.result as? [NSPersistentHistoryTransaction],
                      !transactions.isEmpty
                else { return }

                let viewContext = container.viewContext
                viewContext.performAndWait {
                    for transaction in transactions {
                        guard let userInfo = transaction.objectIDNotification().userInfo else { continue }
                        NSManagedObjectContext.mergeChanges(
                            fromRemoteContextSave: userInfo,
                            into: [viewContext]
                        )
                    }
                }

                if let last = transactions.last?.token {
                    saveToken(last)
                }

                WidgetSnapshotPublisherBridge.scheduleRefreshIfAvailable()
            } catch {
                AppLogger.persistence.error(
                    "Persistent history merge failed: \(error.localizedDescription)"
                )
            }
        }
    }

    private static func loadToken() -> NSPersistentHistoryToken? {
        guard let data = UserDefaults.standard.data(forKey: lastTokenKey) else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(
            ofClass: NSPersistentHistoryToken.self,
            from: data
        )
    }

    private static func saveToken(_ token: NSPersistentHistoryToken) {
        guard let data = try? NSKeyedArchiver.archivedData(
            withRootObject: token,
            requiringSecureCoding: true
        ) else { return }
        UserDefaults.standard.set(data, forKey: lastTokenKey)
    }
}
#endif
