//
//  PersistenceController.swift
//  Cronica
//
//  Created by Alexandre Madeira on 29/01/22.
//  swiftlint:disable trailing_whitespace

import CoreData
import CronicaCore

/// An environment singleton responsible for managing Watchlist Core Data stack, including handling saving,
/// tracking watchlists, and dealing with sample data.
struct PersistenceController {
    static let shared = PersistenceController()
    static let cloudKitContainerIdentifier = "iCloud.dev.alexandremadeira.Story"
    private static let sharedStoreDirectoryName = "Watchlist"
    private static let sharedStoreFileName = "Watchlist.sqlite"

    // MARK: Preview sample
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for item in ItemContent.examples {
            let newItem = WatchlistItem(context: viewContext)
            newItem.title = item.itemTitle
            newItem.id = Int64(item.id)
            newItem.image = item.cardImageMedium
            newItem.contentType = MediaType.movie.toInt
            newItem.notify = Bool.random()
        }
        do {
            try viewContext.save()
        } catch {
            fatalError("Fatal error creating preview: \(error.localizedDescription)")
        }
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Watchlist")
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true

        guard let description = container.persistentStoreDescriptions.first else {
            AppLogger.persistence.fault("Missing persistent store description for Watchlist.")
            return
        }

        // Optional attribute additions (e.g. watchedDate) use lightweight migration.
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true

        if inMemory {
            description.url = URL(fileURLWithPath: "/dev/null")
            description.cloudKitContainerOptions = nil
        } else {
            // App + Share Extension share one on-disk store via the App Group so adds
            // appear without waiting for CloudKit (and still work offline / without iCloud).
            // Watch keeps its own CloudKit-backed store and syncs through iCloud.
#if os(iOS)
            if let sharedStoreURL = Self.sharedAppGroupStoreURL() {
                Self.migrateLegacyStoreIfNeeded(to: sharedStoreURL)
                description.url = sharedStoreURL
            }
#endif

            // Must be configured before loadPersistentStores.
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

            if Self.isICloudAccountAvailable() {
                description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                    containerIdentifier: Self.cloudKitContainerIdentifier
                )
            } else {
                // Local-only when Simulator/device has no iCloud account — avoids CKAccountStatusNoAccount spam.
                description.cloudKitContainerOptions = nil
                AppLogger.persistence.info("iCloud account unavailable; loading watchlist store locally.")
            }
        }

        // CloudKit schema is managed in CloudKit Console (not in-app). After Core Data
        // model changes, add matching fields on CD_* record types in Development, then
        // Deploy Schema Changes → Production. Attribute names must match what
        // NSPersistentCloudKitContainer expects (typically CD_ prefixes).
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
#if DEBUG
                fatalError("Unresolved error \(error), \(error.userInfo)")
#else
                AppLogger.persistence.fault("Unresolved error loading persistent store: \(error), \(error.userInfo)")
#endif
            }
        }
    }

    func save() {
        if container.viewContext.hasChanges {
            do {
                try container.viewContext.save()
#if !CRONICA_SHARE_EXTENSION
                WidgetSnapshotPublisherBridge.scheduleRefreshIfAvailable()
#endif
            } catch {
                AppLogger.persistence.error("Failed to save Core Data context: \(error.localizedDescription)")
#if !os(watchOS) && !CRONICA_SHARE_EXTENSION
                SentryManager.capture(error, context: ["source": "PersistenceController.save"])
#endif
            }
        }
    }

#if !CRONICA_SHARE_EXTENSION
    /// Deletes all watchlist items and custom lists via per-object deletes so CloudKit
    /// receives proper tombstones (unlike `NSBatchDeleteRequest`, which often skips sync).
    func deleteAllUserContent() throws {
        let context = container.viewContext

        let lists = try context.fetch(CustomList.fetchRequest())
        for list in lists {
            context.delete(list)
        }

        let items = try context.fetch(WatchlistItem.fetchRequest())
        for item in items {
            context.delete(item)
        }

        if context.hasChanges {
            try context.save()
        }
    }

    /// Restores a JSON backup, updating existing rows matched by `contentID` instead of duplicating.
    @discardableResult
    func importWatchlistBackup(from data: Data) throws -> (inserted: Int, updated: Int) {
        let backups = try JSONDecoder().decode([WatchlistItemBackup].self, from: data)
        var inserted = 0
        var updated = 0

        for backup in backups where !backup.contentID.isEmpty {
            if let existing = fetch(for: backup.contentID) {
                existing.apply(backup)
                updated += 1
            } else {
                let item = WatchlistItem(context: container.viewContext)
                item.apply(backup)
                inserted += 1
            }
        }

        save()
        return (inserted, updated)
    }

    func exportWatchlistBackup() throws -> Data {
        let items = try container.viewContext.fetch(WatchlistItem.fetchRequest())
        let backups = items.map(WatchlistItemBackup.init(item:))
        return try JSONEncoder().encode(backups)
    }
#endif

    private static func isICloudAccountAvailable() -> Bool {
        // Synchronous signal for whether an iCloud account is signed in on this device/simulator.
        FileManager.default.ubiquityIdentityToken != nil
    }

#if os(iOS)
    private static func sharedAppGroupStoreURL() -> URL? {
        guard let containerURL = WidgetAppGroup.containerURL else { return nil }
        let directory = containerURL
            .appendingPathComponent(sharedStoreDirectoryName, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent(sharedStoreFileName)
    }

    /// Copies a pre-App-Group store into the shared container once so users keep their data.
    private static func migrateLegacyStoreIfNeeded(to sharedStoreURL: URL) {
        let fileManager = FileManager.default
        guard !fileManager.fileExists(atPath: sharedStoreURL.path) else { return }

        let legacyURL = NSPersistentContainer
            .defaultDirectoryURL()
            .appendingPathComponent(sharedStoreFileName)
        guard fileManager.fileExists(atPath: legacyURL.path) else { return }

        do {
            try copySQLiteStore(from: legacyURL, to: sharedStoreURL)
            AppLogger.persistence.info("Migrated watchlist store into App Group container.")
        } catch {
            AppLogger.persistence.error(
                "Failed to migrate watchlist store to App Group: \(error.localizedDescription)"
            )
        }
    }

    private static func copySQLiteStore(from source: URL, to destination: URL) throws {
        let fileManager = FileManager.default
        try fileManager.copyItem(at: source, to: destination)
        for suffix in ["-shm", "-wal"] {
            let sourceSidecar = URL(fileURLWithPath: source.path + suffix)
            let destinationSidecar = URL(fileURLWithPath: destination.path + suffix)
            if fileManager.fileExists(atPath: sourceSidecar.path),
               !fileManager.fileExists(atPath: destinationSidecar.path) {
                try fileManager.copyItem(at: sourceSidecar, to: destinationSidecar)
            }
        }
    }
#endif
}
