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
        for example in ItemContent.examples {
            let item = requireItem(for: example.itemContentID)
            persistence.updateWatched(for: item)
        }
        for item in ItemContent.examples {
            XCTAssertTrue(persistence.isMarkedAsWatched(id: item.itemContentID))
        }
    }
    
    func testRemoveFromWatched() {
        for example in ItemContent.examples {
            let item = requireItem(for: example.itemContentID)
            persistence.updateWatched(for: item)
            persistence.updateWatched(for: item)
        }
        for item in ItemContent.examples {
            XCTAssertFalse(persistence.isMarkedAsWatched(id: item.itemContentID))
        }
    }
    
    func testMarkAsFavorite() {
        for example in ItemContent.examples {
            let item = requireItem(for: example.itemContentID)
            persistence.updateFavorite(for: item)
        }
        for item in ItemContent.examples {
            XCTAssertTrue(persistence.isMarkedAsFavorite(id: item.itemContentID))
        }
    }
    
    func testRemoveFromFavorite() {
        for example in ItemContent.examples {
            let item = requireItem(for: example.itemContentID)
            persistence.updateFavorite(for: item)
            persistence.updateFavorite(for: item)
        }
        for item in ItemContent.examples {
            XCTAssertFalse(persistence.isMarkedAsFavorite(id: item.itemContentID))
        }
    }
    
    func testMarkAsArchive() {
        for example in ItemContent.examples {
            let item = requireItem(for: example.itemContentID)
            persistence.updateArchive(for: item)
        }
        for item in ItemContent.examples {
            XCTAssertTrue(persistence.isItemArchived(id: item.itemContentID))
        }
    }
    
    func testRemoveFromArchive() {
        for example in ItemContent.examples {
            let item = requireItem(for: example.itemContentID)
            persistence.updateArchive(for: item)
            persistence.updateArchive(for: item)
        }
        for item in ItemContent.examples {
            XCTAssertFalse(persistence.isItemArchived(id: item.itemContentID))
        }
    }
    
    func testMarkAsPin() {
        for example in ItemContent.examples {
            let item = requireItem(for: example.itemContentID)
            persistence.updatePin(for: item)
        }
        for item in ItemContent.examples {
            XCTAssertTrue(persistence.isItemPinned(id: item.itemContentID))
        }
    }
    
    func testRemoveFromPins() {
        for example in ItemContent.examples {
            let item = requireItem(for: example.itemContentID)
            persistence.updatePin(for: item)
            persistence.updatePin(for: item)
        }
        for item in ItemContent.examples {
            XCTAssertFalse(persistence.isItemPinned(id: item.itemContentID))
        }
    }
    
    func testRemoveItemsFromWatchlist() {
        for example in ItemContent.examples {
            let item = requireItem(for: example.itemContentID)
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

    func testWatchProgressUsesCachedEpisodeTotal() {
        let item = WatchlistItem(context: managedContext)
        item.title = "Progress Show"
        item.id = 99
        item.contentID = "99@1"
        item.contentType = MediaType.tvShow.toInt
        item.numberOfEpisodes = 10
        item.watchedEpisodes = "-1@1-2@1-3@1"
        item.firstAirDate = Date()

        XCTAssertEqual(item.watchedEpisodeCount, 3)
        XCTAssertEqual(item.watchProgress, 0.3, accuracy: 0.001)
        XCTAssertTrue(item.hasStartedWatching)
    }

    func testHideUnstartedUsesWatchedEpisodeCount() {
        let item = WatchlistItem(context: managedContext)
        item.title = "Unstarted Show"
        item.id = 100
        item.contentID = "100@1"
        item.contentType = MediaType.tvShow.toInt
        item.numberOfEpisodes = 12
        item.watchedEpisodes = ""
        item.isWatching = false
        item.firstAirDate = Date()

        XCTAssertFalse(item.hasStartedWatching)
        XCTAssertEqual(item.watchProgress, 0)
    }

    func testItemUpcomingReleaseDatePrefersStoredEpisodeDate() {
        let episodeDate = Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: 12))!
        let item = WatchlistItem(context: managedContext)
        item.contentType = MediaType.tvShow.toInt
        item.date = episodeDate

        XCTAssertEqual(item.itemUpcomingReleaseDate, episodeDate)
    }

    func testItemUpcomingReleaseDateUsesMovieReleaseDate() {
        let movieDate = Calendar.current.date(from: DateComponents(year: 2026, month: 12, day: 1))!
        let item = WatchlistItem(context: managedContext)
        item.contentType = MediaType.movie.toInt
        item.movieReleaseDate = movieDate

        XCTAssertEqual(item.itemUpcomingReleaseDate, movieDate)
    }

    func testSavingTVShowStoresMidSeasonEpisodeDate() {
        let episodeDate = Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 5))!
        let content = SelfHelper.makeTVContent(id: 501, episodeNumber: 5, seasonNumber: 2, airDate: episodeDate)

        persistence.save(content)
        let saved = requireItem(for: content.itemContentID)

        XCTAssertEqual(saved.date, episodeDate)
        XCTAssertEqual(saved.itemUpcomingReleaseDate, episodeDate)
    }

    private enum SelfHelper {
        static func makeTVContent(id: Int, episodeNumber: Int, seasonNumber: Int, airDate: Date) -> ItemContent {
            let airDateString = DatesManager.dateFormatter.string(from: airDate)
            let episode = Episode(
                id: id * 10,
                episodeNumber: episodeNumber,
                seasonNumber: seasonNumber,
                name: "Episode \(episodeNumber)",
                overview: nil,
                stillPath: nil,
                airDate: airDateString
            )
            return ItemContent(
                adult: nil,
                id: id,
                title: nil,
                name: "Series \(id)",
                overview: nil,
                originalTitle: nil,
                posterPath: nil,
                backdropPath: nil,
                profilePath: nil,
                releaseDate: nil,
                status: nil,
                imdbId: nil,
                runtime: nil,
                numberOfEpisodes: 12,
                numberOfSeasons: Int(seasonNumber),
                voteCount: nil,
                popularity: nil,
                voteAverage: nil,
                productionCompanies: nil,
                productionCountries: nil,
                seasons: nil,
                genres: nil,
                credits: nil,
                recommendations: nil,
                releaseDates: nil,
                mediaType: "tv",
                videos: nil,
                nextEpisodeToAir: episode,
                lastEpisodeToAir: nil,
                originalName: nil,
                firstAirDate: nil,
                homepage: nil,
                episodeRunTime: nil,
                placeholderImagePath: nil
            )
        }
    }

    private func requireItem(for contentID: String,
                             file: StaticString = #filePath,
                             line: UInt = #line) -> WatchlistItem {
        guard let item = persistence.fetch(for: contentID) else {
            XCTFail("Expected watchlist item for \(contentID)", file: file, line: line)
            fatalError("Missing watchlist item for \(contentID)")
        }
        return item
    }
}
