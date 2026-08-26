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
    private static var isMerging = false

    private final class HistoryFetchScratch: @unchecked Sendable {
        var mergePayloads: [[AnyHashable: Any]] = []
        var lastToken: NSPersistentHistoryToken?
        var error: Error?
    }

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

        let scratch = HistoryFetchScratch()
        let background = container.newBackgroundContext()
        background.performAndWait {
            do {
                let token = loadToken()
                let request = NSPersistentHistoryChangeRequest.fetchHistory(after: token)
                guard let result = try background.execute(request) as? NSPersistentHistoryResult,
                      let transactions = result.result as? [NSPersistentHistoryTransaction],
                      !transactions.isEmpty
                else { return }

                scratch.mergePayloads = transactions.compactMap { $0.objectIDNotification().userInfo }
                scratch.lastToken = transactions.last?.token
            } catch {
                scratch.error = error
            }
        }

        if let error = scratch.error {
            AppLogger.persistence.error(
                "Persistent history merge failed: \(error.localizedDescription)"
            )
            return
        }
        guard !scratch.mergePayloads.isEmpty else { return }

        for userInfo in scratch.mergePayloads {
            NSManagedObjectContext.mergeChanges(
                fromRemoteContextSave: userInfo,
                into: [container.viewContext]
            )
        }

        if let lastToken = scratch.lastToken {
            saveToken(lastToken)
        }

        WidgetSnapshotPublisherBridge.scheduleRefreshIfAvailable()
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
