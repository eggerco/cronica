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

    private static let managedObjectModel: NSManagedObjectModel = {
        guard let modelURL = Bundle.main.url(forResource: "Watchlist", withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to load Watchlist Core Data model from the app bundle.")
        }
        return model
    }()

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
    
    let container: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "Watchlist", managedObjectModel: PersistenceController.managedObjectModel)
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
#if DEBUG
                fatalError("Unresolved error \(error), \(error.userInfo)")
#else
                AppLogger.persistence.fault("Unresolved error loading persistent store: \(error), \(error.userInfo)")
#endif
            }
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            
        }
#if DEBUG && os(iOS)
        do {
            try container.initializeCloudKitSchema()
        } catch {
            print("initializeCloudKitSchema: \(error.localizedDescription)")
        }
#endif
        return container
    }()
    
    init(inMemory: Bool = false) {
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
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
}
