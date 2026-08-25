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

    func testDeleteAllUserContentRemovesItemsAndLists() throws {
        _ = persistence.createList(
            title: "Test List",
            description: "Notes",
            items: Set(ItemContent.examples.compactMap { persistence.fetch(for: $0.itemContentID) }),
            isPin: false
        )

        try persistence.deleteAllUserContent()

        XCTAssertEqual(try managedContext.count(for: WatchlistItem.fetchRequest()), 0)
        XCTAssertEqual(try managedContext.count(for: CustomList.fetchRequest()), 0)
    }

    func testWatchlistBackupImportUpdatesInsteadOfDuplicating() throws {
        guard let example = ItemContent.examples.first else {
            XCTFail("Expected preview content")
            return
        }
        let existing = requireItem(for: example.itemContentID)
        existing.userNotes = "before"
        existing.watched = false
        persistence.save()

        let data = try persistence.exportWatchlistBackup()
        let result = try persistence.importWatchlistBackup(from: data)
        XCTAssertEqual(result.inserted, 0)
        XCTAssertGreaterThanOrEqual(result.updated, 1)

        let request: NSFetchRequest<WatchlistItem> = WatchlistItem.fetchRequest()
        request.predicate = NSPredicate(format: "contentID == %@", example.itemContentID)
        XCTAssertEqual(try managedContext.count(for: request), 1)

        // Mutate exported payload and re-import as an update.
        var backups = try JSONDecoder().decode([WatchlistItemBackup].self, from: data)
        backups = backups.map { backup in
            var updated = backup
            if updated.contentID == example.itemContentID {
                updated.userNotes = "after restore"
                updated.watched = true
            }
            return updated
        }
        let updatedData = try JSONEncoder().encode(backups)
        _ = try persistence.importWatchlistBackup(from: updatedData)

        let restored = requireItem(for: example.itemContentID)
        XCTAssertEqual(restored.userNotes, "after restore")
        XCTAssertTrue(restored.watched)
        XCTAssertEqual(try managedContext.count(for: request), 1)
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

    func testSimklContentIDUsesTMDBAndMediaType() {
        XCTAssertEqual(SimklImportMapper.contentID(tmdbID: 1981, media: .tvShow), "1981@1")
        XCTAssertEqual(SimklImportMapper.contentID(tmdbID: 550, media: .movie), "550@0")
    }

    func testSimklRatingMapsTenPointScaleToFiveStars() {
        XCTAssertEqual(SimklImportMapper.cronicaRating(fromSimkl: 10), 5)
        XCTAssertEqual(SimklImportMapper.cronicaRating(fromSimkl: 9), 5)
        XCTAssertEqual(SimklImportMapper.cronicaRating(fromSimkl: 1), 1)
        XCTAssertEqual(SimklImportMapper.cronicaRating(fromSimkl: 0), 0)
    }

    func testSimklAnimeWithoutTMDBIsSkipped() throws {
        let json = """
        {"status":"completed","show":{"title":"Cowboy Bebop","ids":{"simkl":37089,"mal":"1"}}}
        """.data(using: .utf8)!
        let entry = try JSONDecoder().decode(SimklLibraryEntry.self, from: json)
        XCTAssertTrue(SimklImportMapper.shouldSkipAnimeWithoutTMDB(entry))
    }

    func testSimklFlexibleIDDecodesStringOrInt() throws {
        let stringJSON = "\"1981\"".data(using: .utf8)!
        let intJSON = "1981".data(using: .utf8)!
        XCTAssertEqual(try JSONDecoder().decode(FlexibleID.self, from: stringJSON).intValue, 1981)
        XCTAssertEqual(try JSONDecoder().decode(FlexibleID.self, from: intJSON).intValue, 1981)
    }

    func testSimklApplyStatusMarksCompletedMovieWatched() {
        let item = WatchlistItem(context: managedContext)
        item.title = "Pulp Fiction"
        item.id = 680
        item.contentID = "680@0"
        item.contentType = MediaType.movie.toInt
        persistence.save()

        let entry = SimklLibraryEntry(
            status: .completed,
            watchedEpisodesCount: 0,
            totalEpisodesCount: 0,
            userRating: 10,
            lastWatchedAt: nil,
            movie: SimklMediaObject(title: "Pulp Fiction", year: 1994, ids: SimklIDs(simkl: 1, tmdb: .int(680), imdb: nil, tvdb: nil, slug: nil)),
            show: nil,
            seasons: nil,
            animeType: nil
        )
        SimklImportMapper.applyStatus(entry, to: "680@0", media: .movie)
        let saved = requireItem(for: "680@0")
        XCTAssertTrue(saved.watched)
        XCTAssertFalse(saved.isArchive)
        XCTAssertEqual(saved.userRating, 5)
    }

    func testSimklEpisodeTokensUseExistingFormat() {
        let entry = SimklLibraryEntry(
            status: .watching,
            seasons: [
                SimklSeason(
                    number: 1,
                    episodes: [
                        SimklEpisode(number: 1, watchedAt: "2024-01-01"),
                        SimklEpisode(number: 2, watchedAt: "2024-01-02"),
                        SimklEpisode(number: 3, watchedAt: nil)
                    ]
                )
            ]
        )
        XCTAssertEqual(
            SimklImportMapper.watchedEpisodeTokens(from: entry),
            ["-1@1", "-2@1"]
        )
        XCTAssertEqual(SimklImportMapper.episodeToken(episode: 4, season: 2), "-4@2")
    }

    func testSimklDroppedStatusArchivesItem() {
        let item = WatchlistItem(context: managedContext)
        item.title = "Dropped Show"
        item.id = 999
        item.contentID = "999@1"
        item.contentType = MediaType.tvShow.toInt
        persistence.save()

        let entry = SimklLibraryEntry(status: .dropped, show: SimklMediaObject(title: "Dropped Show", ids: SimklIDs(tmdb: .int(999))))
        SimklImportMapper.applyStatus(entry, to: "999@1", media: .tvShow)
        let saved = requireItem(for: "999@1")
        XCTAssertTrue(saved.isArchive)
        XCTAssertFalse(saved.watched)
        XCTAssertFalse(saved.isWatching)
    }

    func testSimklTokenStoreRoundTrip() throws {
        defer { SimklTokenStore.delete() }
        SimklTokenStore.delete()
        XCTAssertFalse(SimklTokenStore.hasToken)
        try SimklTokenStore.save("unit-test-token")
        XCTAssertEqual(SimklTokenStore.load(), "unit-test-token")
        XCTAssertTrue(SimklTokenStore.hasToken)
        SimklTokenStore.delete()
        XCTAssertNil(SimklTokenStore.load())
        XCTAssertFalse(SimklTokenStore.hasToken)
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
