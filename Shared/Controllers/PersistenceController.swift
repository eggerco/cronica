//
//  PersistenceController.swift
//  Cronica
//
//  Created by Alexandre Madeira on 29/01/22.
//  swiftlint:disable trailing_whitespace

import CoreData
import CloudKit

/// An environment singleton responsible for managing Watchlist Core Data stack, including handling saving,
/// tracking watchlists, and dealing with sample data.
struct PersistenceController {
    static let shared = PersistenceController()
    static let cloudKitContainerIdentifier = "iCloud.dev.alexandremadeira.Story"

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

        // Capture locally so the escaping load callback does not retain mutating `self`
        // (PersistenceController is a struct; property access inside init would capture self).
        let loadedContainer = container
        loadedContainer.loadPersistentStores { _, error in
            if let error = error as NSError? {
#if DEBUG
                fatalError("Unresolved error \(error), \(error.userInfo)")
#else
                AppLogger.persistence.fault("Unresolved error loading persistent store: \(error), \(error.userInfo)")
#endif
            }
#if DEBUG
            // Development environment only — never run in App Store Release builds.
            // After model changes, launch a DEBUG build signed into iCloud, then promote
            // the schema in CloudKit Console (Deploy Schema Changes → Production).
            if !inMemory {
                Self.initializeDevelopmentCloudKitSchema(for: loadedContainer)
            }
#endif
        }
    }

#if DEBUG
    /// Pushes the current Core Data model into the CloudKit **development** schema.
    /// Safe to call on DEBUG launches when iCloud + CloudKit are available; no-op otherwise.
    private static func initializeDevelopmentCloudKitSchema(for container: NSPersistentCloudKitContainer) {
        guard isICloudAccountAvailable(),
              container.persistentStoreDescriptions.first?.cloudKitContainerOptions != nil else {
            AppLogger.persistence.info(
                "Skipping CloudKit schema init (sign in to iCloud on a DEBUG build after Core Data model changes)."
            )
            return
        }
        do {
            try container.initializeCloudKitSchema(options: [])
            AppLogger.persistence.info(
                "CloudKit development schema initialized. Promote in CloudKit Console → Deploy Schema Changes for production."
            )
        } catch {
            AppLogger.persistence.error("initializeCloudKitSchema failed: \(error.localizedDescription)")
        }
    }
#endif

    func save() {
        if container.viewContext.hasChanges {
            do {
                try container.viewContext.save()
            } catch {
                AppLogger.persistence.error("Failed to save Core Data context: \(error.localizedDescription)")
#if !os(watchOS)
                SentryManager.capture(error, context: ["source": "PersistenceController.save"])
#endif
            }
        }
    }

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

    private static func isICloudAccountAvailable() -> Bool {
        // Synchronous signal for whether an iCloud account is signed in on this device/simulator.
        FileManager.default.ubiquityIdentityToken != nil
    }
}
