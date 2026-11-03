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

    /// Carries the original `objectIDNotification().userInfo` dictionaries across the
    /// background-context hop without reshaping keys (mergeChanges expects that payload).
    private final class HistoryFetchResult: @unchecked Sendable {
        let mergePayloads: [[AnyHashable: Any]]
        let tokenData: Data?

        init(mergePayloads: [[AnyHashable: Any]], tokenData: Data?) {
            self.mergePayloads = mergePayloads
            self.tokenData = tokenData
        }
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
                    guard let historyResult = try background.execute(request) as? NSPersistentHistoryResult,
                          let transactions = historyResult.result as? [NSPersistentHistoryTransaction],
                          let lastTransaction = transactions.last
                    else {
                        return HistoryFetchResult(mergePayloads: [], tokenData: nil)
                    }

                    let payloads = transactions.compactMap { $0.objectIDNotification().userInfo }
                    let tokenData = try? NSKeyedArchiver.archivedData(
                        withRootObject: lastTransaction.token,
                        requiringSecureCoding: true
                    )
                    return HistoryFetchResult(mergePayloads: payloads, tokenData: tokenData)
                }
                if !result.mergePayloads.isEmpty {
                    for userInfo in result.mergePayloads {
                        NSManagedObjectContext.mergeChanges(
                            fromRemoteContextSave: userInfo,
                            into: [container.viewContext]
                        )
                    }
                    if let tokenData = result.tokenData {
                        UserDefaults.standard.set(tokenData, forKey: lastTokenKey)
                    } else {
                        AppLogger.persistence.error(
                            "Persistent history token archive failed; history may re-merge"
                        )
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
