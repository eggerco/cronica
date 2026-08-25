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

    /// Development-only: push the current Core Data model into the CloudKit **development** schema.
    /// Call from Developer Options after model changes while signed into iCloud — not on every launch.
    @discardableResult
    func initializeCloudKitDevelopmentSchema() -> String {
        guard Self.isICloudAccountAvailable() else {
            return "Sign in to iCloud on this device/simulator first."
        }
        do {
            try container.initializeCloudKitSchema(options: [])
            return "CloudKit development schema initialized."
        } catch {
            AppLogger.persistence.error("initializeCloudKitSchema failed: \(error.localizedDescription)")
            return error.localizedDescription
        }
    }

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

    func deleteAllUserContent() throws {
        let context = container.viewContext
        try batchDelete(entityName: "WatchlistItem", in: context)
        try batchDelete(entityName: "CustomList", in: context)
        save()
    }

    private func batchDelete(entityName: String, in context: NSManagedObjectContext) throws {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        deleteRequest.resultType = .resultTypeObjectIDs
        let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
        if let objectIDs = result?.result as? [NSManagedObjectID] {
            NSManagedObjectContext.mergeChanges(
                fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs],
                into: [context]
            )
        }
    }

    private static func isICloudAccountAvailable() -> Bool {
        // Synchronous signal for whether an iCloud account is signed in on this device/simulator.
        FileManager.default.ubiquityIdentityToken != nil
    }
}
