//
//  CronicaTests.swift
//  CronicaTests
//
//  Created by Alexandre Madeira on 28/10/23.
//

import XCTest
import CoreData
@testable import Cronica

final class CronicaTests: XCTestCase {
    var persistence: PersistenceController!
    var managedContext: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        persistence = PersistenceController(inMemory: true)
        managedContext = persistence.container.viewContext
        for item in ItemContent.examples {
            persistence.save(item)
        }
    }
    
    func testAddItemsToWatchlist() {
        for item in ItemContent.examples {
            persistence.save(item)
        }
        for item in ItemContent.examples {
            XCTAssertTrue(persistence.isItemSaved(id: item.itemContentID))
        }
    }
    
    func testMarkAsWatched() {
        for item in ItemContent.examples {
            guard let item = persistence.fetch(for: item.itemContentID) else { return }
            persistence.updateWatched(for: item)
        }
        for item in ItemContent.examples {
            XCTAssertTrue(persistence.isMarkedAsWatched(id: item.itemContentID))
        }
    }
    
    func testRemoveFromWatched() {
        for item in ItemContent.examples {
            guard let item = persistence.fetch(for: item.itemContentID) else { return }
            persistence.updateWatched(for: item)
            persistence.updateWatched(for: item)
        }
        for item in ItemContent.examples {
            XCTAssertFalse(persistence.isMarkedAsWatched(id: item.itemContentID))
        }
    }
    
    func testMarkAsFavorite() {
        for item in ItemContent.examples {
            guard let item = persistence.fetch(for: item.itemContentID) else { return }
            persistence.updateFavorite(for: item)
        }
        for item in ItemContent.examples {
            XCTAssertTrue(persistence.isMarkedAsFavorite(id: item.itemContentID))
        }
    }
    
    func testRemoveFromFavorite() {
        for item in ItemContent.examples {
            guard let item = persistence.fetch(for: item.itemContentID) else { return }
            persistence.updateFavorite(for: item)
            persistence.updateFavorite(for: item)
        }
        for item in ItemContent.examples {
            XCTAssertFalse(persistence.isMarkedAsFavorite(id: item.itemContentID))
        }
    }
    
    func testMarkAsArchive() {
        for item in ItemContent.examples {
            guard let item = persistence.fetch(for: item.itemContentID) else { return }
            persistence.updateArchive(for: item)
        }
        for item in ItemContent.examples {
            XCTAssertTrue(persistence.isItemArchived(id: item.itemContentID))
        }
    }
    
    func testRemoveFromArchive() {
        for item in ItemContent.examples {
            guard let item = persistence.fetch(for: item.itemContentID) else { return }
            persistence.updateArchive(for: item)
            persistence.updateArchive(for: item)
        }
        for item in ItemContent.examples {
            XCTAssertFalse(persistence.isItemArchived(id: item.itemContentID))
        }
    }
    
    func testMarkAsPin() {
        for item in ItemContent.examples {
            guard let item = persistence.fetch(for: item.itemContentID) else { return }
            persistence.updatePin(for: item)
        }
        for item in ItemContent.examples {
            XCTAssertTrue(persistence.isItemPinned(id: item.itemContentID))
        }
    }
    
    func testRemoveFromPins() {
        for item in ItemContent.examples {
            guard let item = persistence.fetch(for: item.itemContentID) else { return }
            persistence.updatePin(for: item)
            persistence.updatePin(for: item)
        }
        for item in ItemContent.examples {
            XCTAssertFalse(persistence.isItemPinned(id: item.itemContentID))
        }
    }
    
    func testRemoveItemsFromWatchlist() {
        for item in ItemContent.examples {
            guard let item = persistence.fetch(for: item.itemContentID) else { return }
            persistence.delete(item)
        }
        for item in ItemContent.examples {
            XCTAssertFalse(persistence.isItemSaved(id: item.itemContentID))
        }
    }
    
    func testKeyConfigurationDefaultsAreSafe() {
        XCTAssertFalse(Key.tmdbApi.contains("YOUR_"))
    }
    
    func testNetworkErrorDescriptionsAreNonEmpty() {
        let errors: [NetworkError] = [
            .invalidResponse, .invalidRequest, .invalidEndpoint, .decodingError,
            .invalidApi, .internalError, .maintenanceApi, .contentRemoved
        ]
        for error in errors {
            XCTAssertFalse(error.localizedName.isEmpty)
        }
    }
    
    func testPersistenceSaveDoesNotDuplicateItems() {
        guard let item = ItemContent.examples.first else {
            XCTFail("Expected preview content")
            return
        }
        persistence.save(item)
        persistence.save(item)
        let request: NSFetchRequest<WatchlistItem> = WatchlistItem.fetchRequest()
        request.predicate = NSPredicate(format: "contentID == %@", item.itemContentID)
        let count = try? managedContext.count(for: request)
        XCTAssertEqual(count, 1)
    }
    
}
