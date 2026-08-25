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
    

    func testWatchedDateSetAndCleared() {
        let example = ItemContent.examples[0]
        let item = requireItem(for: example.itemContentID)
        XCTAssertNil(item.watchedDate)
        persistence.updateWatched(for: item)
        XCTAssertTrue(item.isWatched)
        XCTAssertNotNil(item.watchedDate)
        let custom = Date(timeIntervalSince1970: 1_700_000_000)
        persistence.updateWatchedDate(for: item, date: custom)
        XCTAssertEqual(item.watchedDate, custom)
        persistence.updateWatched(for: item)
        XCTAssertFalse(item.isWatched)
        XCTAssertNil(item.watchedDate)
    }

    /// Marking Watched auto-saves into the watchlist; default Released filter must still show it
    /// (Unwatched is the to-watch queue). Regression: watched titles vanished from Released.
    func testWatchedItemStaysVisibleInReleasedFilter() {
        let item = WatchlistItem(context: managedContext)
        item.title = "Released Movie"
        item.id = 4242
        item.contentID = "4242@0"
        item.contentType = MediaType.movie.toInt
        item.schedule = ItemSchedule.released.toInt
        item.notify = false
        item.date = Date().addingTimeInterval(-86_400)
        item.watched = false
        persistence.save()

        XCTAssertTrue(persistence.isItemSaved(id: "4242@0"))
        XCTAssertTrue(item.isReleased)

        persistence.updateWatched(for: item)

        XCTAssertTrue(item.isWatched)
        XCTAssertTrue(persistence.isItemSaved(id: "4242@0"))
        XCTAssertTrue(item.isReleased, "Released is schedule-based; watched titles must not leave the default filter")
        XCTAssertFalse(!item.isCurrentlyWatching && !item.isWatched && item.isReleased,
                       "Unwatched filter should exclude newly watched titles")
    }

    func testMarkWatchedOnUnsavedTitlePersistsLikeManualAdd() {
        guard let content = ItemContent.examples.first else {
            XCTFail("Expected preview content")
            return
        }
        if let existing = persistence.fetch(for: content.itemContentID) {
            persistence.delete(existing)
        }
        XCTAssertFalse(persistence.isItemSaved(id: content.itemContentID))

        // Mirrors ItemContentViewModel.update(.watched): auto-add then mark watched.
        persistence.save(content)
        let item = requireItem(for: content.itemContentID)
        persistence.updateWatched(for: item)

        XCTAssertTrue(persistence.isItemSaved(id: content.itemContentID))
        XCTAssertTrue(persistence.isMarkedAsWatched(id: content.itemContentID))
        XCTAssertNotNil(item.watchedDate)
    }

    func testParseSimklWatchedDate() {
        XCTAssertNotNil(SimklImportMapper.parseSimklDate("2024-01-15T12:00:00Z"))
        XCTAssertNotNil(SimklImportMapper.parseSimklDate("2024-01-15"))
        XCTAssertNil(SimklImportMapper.parseSimklDate(nil))
        XCTAssertNil(SimklImportMapper.parseSimklDate(""))
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
        XCTAssertEqual(item.watchProgressLabel, "30% watched")
    }

    func testWatchlistSortByWatchedDate() {
        let older = WatchlistItem(context: managedContext)
        older.title = "Older"
        older.id = 1
        older.contentID = "1@0"
        older.contentType = MediaType.movie.toInt
        older.watched = true
        older.watchedDate = Date(timeIntervalSince1970: 1_000)

        let newer = WatchlistItem(context: managedContext)
        newer.title = "Newer"
        newer.id = 2
        newer.contentID = "2@0"
        newer.contentType = MediaType.movie.toInt
        newer.watched = true
        newer.watchedDate = Date(timeIntervalSince1970: 2_000)

        let list = CustomList(context: managedContext)
        list.id = UUID()
        list.title = "Sort Test"
        list.items = [older, newer] as NSSet
        persistence.save()

        XCTAssertEqual(list.sortedItems(by: .watchedDateDesc).map(\.itemTitle), ["Newer", "Older"])
        XCTAssertEqual(list.sortedItems(by: .watchedDateAsc).map(\.itemTitle), ["Older", "Newer"])
    }

    func testSimklTimestampIsISO8601() {
        let date = Date(timeIntervalSince1970: 1_724_000_000)
        let stamp = SimklPushService.simklTimestamp(date)
        XCTAssertTrue(stamp.contains("T"))
        XCTAssertTrue(stamp.hasSuffix("Z") || stamp.contains("+") || stamp.contains("-"))
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

    @MainActor
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
        SimklImportMapper.applyStatus(entry, to: "680@0", media: .movie, persistence: persistence)
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

    @MainActor
    func testSimklDroppedStatusArchivesItem() {
        let item = WatchlistItem(context: managedContext)
        item.title = "Dropped Show"
        item.id = 999
        item.contentID = "999@1"
        item.contentType = MediaType.tvShow.toInt
        persistence.save()

        let entry = SimklLibraryEntry(status: .dropped, show: SimklMediaObject(title: "Dropped Show", ids: SimklIDs(tmdb: .int(999))))
        SimklImportMapper.applyStatus(entry, to: "999@1", media: .tvShow, persistence: persistence)
        let saved = requireItem(for: "999@1")
        XCTAssertTrue(saved.isArchive)
        XCTAssertFalse(saved.watched)
        XCTAssertFalse(saved.isWatching)
    }

    func testSimklTokenStoreRoundTrip() throws {
        defer { SimklTokenStore.delete() }
        SimklTokenStore.delete()
        XCTAssertFalse(SimklTokenStore.hasToken)
        do {
            try SimklTokenStore.save("unit-test-token")
        } catch {
            throw XCTSkip("Keychain unavailable in this test environment: \(error.localizedDescription)")
        }
        XCTAssertEqual(SimklTokenStore.load(), "unit-test-token")
        XCTAssertTrue(SimklTokenStore.hasToken)
        SimklTokenStore.delete()
        XCTAssertNil(SimklTokenStore.load())
        XCTAssertFalse(SimklTokenStore.hasToken)
    }

    func testSimklActivitiesDecodeNestedBuckets() throws {
        let json = """
        {"all":"2026-05-08T14:23:11Z","movies":{"all":"2026-05-08T14:20:00Z","removed_from_list":"2026-05-08T14:21:00Z"},"tv_shows":{"all":"2026-05-08T14:22:00Z","watching":"2026-05-08T14:22:00Z"},"anime":{"all":"2026-05-01T00:00:00Z"}}
        """.data(using: .utf8)!
        let activities = try JSONDecoder().decode(SimklActivitiesResponse.self, from: json)
        XCTAssertEqual(activities.all, "2026-05-08T14:23:11Z")
        XCTAssertEqual(activities.movies?.removedFromList, "2026-05-08T14:21:00Z")
        XCTAssertEqual(activities.tvShows?.watching, "2026-05-08T14:22:00Z")
    }

    func testSimklKnownItemsStoreTracksContentIDs() {
        defer { SimklKnownItemsStore.clear() }
        SimklKnownItemsStore.clear()
        SimklKnownItemsStore.insert("680@0")
        SimklKnownItemsStore.insert("1981@1")
        XCTAssertEqual(SimklKnownItemsStore.all(), Set(["680@0", "1981@1"]))
        SimklKnownItemsStore.replace(with: ["680@0"])
        XCTAssertEqual(SimklKnownItemsStore.all(), Set(["680@0"]))
    }

    func testSimklPushOperationRoundTrip() throws {
        let ops: [SimklPushService.Operation] = [
            .addToList(tmdb: 680, media: 0, status: "plantowatch", imdb: "tt0110912"),
            .history(tmdb: 1399, media: 1, season: 1, episode: 1, imdb: nil, watchedAt: "2026-08-25T12:00:00Z"),
            .removeHistory(tmdb: 550, media: 0, imdb: nil)
        ]
        let data = try JSONEncoder().encode(ops)
        let decoded = try JSONDecoder().decode([SimklPushService.Operation].self, from: data)
        XCTAssertEqual(decoded, ops)
    }

    func testSimklHistoryPayloadEncodesTMDBIds() throws {
        let payload = SimklHistoryPayload(
            movies: [SimklHistoryItem(ids: SimklWriteIds(tmdb: 680), watchedAt: nil, seasons: nil)],
            shows: [
                SimklHistoryItem(
                    ids: SimklWriteIds(tmdb: 1399),
                    watchedAt: nil,
                    seasons: [SimklHistorySeason(number: 1, episodes: [SimklHistoryEpisode(number: 1)])]
                )
            ]
        )
        let data = try JSONEncoder().encode(payload)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertTrue(json.contains("\"tmdb\":680"))
        XCTAssertTrue(json.contains("\"tmdb\":1399"))
        XCTAssertTrue(json.contains("\"number\":1"))
    }

    func testSimklForegroundThrottleSkipsRapidRechecks() {
        let now: TimeInterval = 1_000_000
        XCTAssertFalse(SimklSyncService.shouldSkipForegroundCheck(lastCheck: 0, now: now))
        XCTAssertTrue(SimklSyncService.shouldSkipForegroundCheck(lastCheck: now - 60, now: now))
        XCTAssertFalse(SimklSyncService.shouldSkipForegroundCheck(lastCheck: now - (21 * 60), now: now))
    }

    func testSimklNeedsEpisodeExtendedWhenWatchingBucketMoves() {
        let activities = SimklActivitiesResponse(
            all: "2026-05-08T14:23:11Z",
            movies: nil,
            tvShows: SimklActivitiesBucket(watching: "2026-05-08T14:23:11Z"),
            anime: nil
        )
        XCTAssertTrue(
            SimklSyncService.needsEpisodeExtended(
                activities: activities,
                previousTVWatching: "2026-05-01T00:00:00Z",
                previousTVHold: "",
                previousAnimeWatching: "",
                previousAnimeHold: ""
            )
        )
        XCTAssertFalse(
            SimklSyncService.needsEpisodeExtended(
                activities: activities,
                previousTVWatching: "2026-05-08T14:23:11Z",
                previousTVHold: "",
                previousAnimeWatching: "",
                previousAnimeHold: ""
            )
        )
    }

    func testSimklRatingRoundTripFiveStarsToTen() {
        XCTAssertEqual(SimklImportMapper.simklRating(fromCronica: 5), 10)
        XCTAssertEqual(SimklImportMapper.simklRating(fromCronica: 1), 2)
        XCTAssertEqual(SimklImportMapper.simklRating(fromCronica: 0), 0)
        XCTAssertEqual(SimklImportMapper.cronicaRating(fromSimkl: 10), 5)
    }

    func testSimklUserStatsDecodeTotalMins() throws {
        let json = """
        {"total_mins":120,"movies":{"total_mins":60,"completed":{"mins":60,"count":2}},"tv":{"total_mins":60,"completed":{"mins":60,"count":1}},"watched_last_week":{"total_mins":30,"movies_mins":10,"tv_mins":20,"anime_mins":0}}
        """.data(using: .utf8)!
        let stats = try JSONDecoder().decode(SimklUserStats.self, from: json)
        XCTAssertEqual(stats.totalMins, 120)
        XCTAssertEqual(stats.movies?.completed?.count, 2)
        XCTAssertEqual(stats.watchedLastWeek?.totalMins, 30)
        XCTAssertTrue(stats.totalHoursText.contains("2"))
    }

    // MARK: - Library import

    func testLibraryImportTenPointRatingMapsToFiveStars() {
        XCTAssertEqual(LibraryImportService.cronicaRating(fromTenPoint: 10), 5)
        XCTAssertEqual(LibraryImportService.cronicaRating(fromTenPoint: 9), 5)
        XCTAssertEqual(LibraryImportService.cronicaRating(fromTenPoint: 1), 1)
        XCTAssertEqual(LibraryImportService.cronicaRating(fromTenPoint: 0), 0)
    }

    func testLibraryImportCronicaRatingMapsToTenPoint() {
        XCTAssertEqual(LibraryImportService.tenPointRating(fromCronica: 5), 10)
        XCTAssertEqual(LibraryImportService.tenPointRating(fromCronica: 1), 2)
        XCTAssertEqual(LibraryImportService.tenPointRating(fromCronica: 0), 0)
        XCTAssertEqual(
            LibraryImportService.cronicaRating(fromTenPoint: LibraryImportService.tenPointRating(fromCronica: 4)),
            4
        )
    }

    func testTMDBSessionStoreRoundTripAndClear() throws {
        defer { TMDBSessionStore.delete() }
        TMDBSessionStore.delete()
        XCTAssertFalse(TMDBSessionStore.hasSession)
        do {
            try TMDBSessionStore.saveSessionID("unit-test-tmdb-session")
        } catch {
            throw XCTSkip("Keychain unavailable in this test environment: \(error.localizedDescription)")
        }
        TMDBSessionStore.saveAccountID(42)
        XCTAssertEqual(TMDBSessionStore.loadSessionID(), "unit-test-tmdb-session")
        XCTAssertEqual(TMDBSessionStore.loadAccountID(), 42)
        XCTAssertTrue(TMDBSessionStore.hasSession)
        TMDBSessionStore.delete()
        XCTAssertNil(TMDBSessionStore.loadSessionID())
        XCTAssertEqual(TMDBSessionStore.loadAccountID(), 0)
        XCTAssertFalse(TMDBSessionStore.hasSession)
    }

    func testTMDBForegroundThrottleMatchesSimklInterval() {
        let now: TimeInterval = 1_000_000
        XCTAssertFalse(TMDBSyncService.shouldSkipForegroundCheck(lastCheck: 0, now: now))
        XCTAssertTrue(
            TMDBSyncService.shouldSkipForegroundCheck(
                lastCheck: now - 60,
                now: now
            )
        )
        XCTAssertFalse(
            TMDBSyncService.shouldSkipForegroundCheck(
                lastCheck: now - TMDBSyncService.foregroundThrottleInterval - 1,
                now: now
            )
        )
    }

    @MainActor
    func testIntegrationRemoteApplySuppressesOutboundPush() {
        XCTAssertFalse(IntegrationRemoteApply.shouldSuppressOutboundPush)
        IntegrationRemoteApply.begin()
        XCTAssertTrue(IntegrationRemoteApply.shouldSuppressOutboundPush)
        IntegrationRemoteApply.begin()
        XCTAssertTrue(IntegrationRemoteApply.shouldSuppressOutboundPush)
        IntegrationRemoteApply.end()
        XCTAssertTrue(IntegrationRemoteApply.shouldSuppressOutboundPush)
        IntegrationRemoteApply.end()
        XCTAssertFalse(IntegrationRemoteApply.shouldSuppressOutboundPush)
    }

    func testTMDBAccountListFingerprintStableAndClears() {
        defer { TMDBAccountListCache.clear() }
        TMDBAccountListCache.clear()
        let items = [
            TMDBAccountAPIClient.AccountMediaItem(id: 2, title: "B", name: nil, releaseDate: nil, firstAirDate: nil, rating: nil),
            TMDBAccountAPIClient.AccountMediaItem(id: 1, title: "A", name: nil, releaseDate: nil, firstAirDate: nil, rating: 8)
        ]
        let empty: [TMDBAccountAPIClient.AccountMediaItem] = []
        let fp1 = TMDBAccountListCache.fingerprint(
            watchlistMovies: items,
            watchlistTV: empty,
            ratedMovies: empty,
            ratedTV: empty,
            favoriteMovies: empty,
            favoriteTV: empty
        )
        let fp2 = TMDBAccountListCache.fingerprint(
            watchlistMovies: items.reversed(),
            watchlistTV: empty,
            ratedMovies: empty,
            ratedTV: empty,
            favoriteMovies: empty,
            favoriteTV: empty
        )
        XCTAssertEqual(fp1, fp2)
        TMDBAccountListCache.saveFingerprint(fp1)
        XCTAssertEqual(TMDBAccountListCache.loadFingerprint(), fp1)
        TMDBAccountListCache.clear()
        XCTAssertNil(TMDBAccountListCache.loadFingerprint())
    }

        func testTMDBPushOperationRoundTrip() throws {
        let ops: [TMDBPushService.Operation] = [
            .watchlist(tmdb: 680, media: 0, onList: true),
            .favorite(tmdb: 1396, media: 1, isFavorite: true),
            .rating(tmdb: 550, media: 0, value: 8),
            .removeRating(tmdb: 550, media: 0)
        ]
        let data = try JSONEncoder().encode(ops)
        let decoded = try JSONDecoder().decode([TMDBPushService.Operation].self, from: data)
        XCTAssertEqual(decoded, ops)
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

    func testMediaTypeFiltersApplySeparatesMoviesAndTVShows() {
        let movie = WatchlistItem(context: managedContext)
        movie.contentType = MediaType.movie.toInt
        movie.title = "Movie"
        movie.contentID = "1@0"

        let show = WatchlistItem(context: managedContext)
        show.contentType = MediaType.tvShow.toInt
        show.title = "Show"
        show.contentID = "2@1"

        let items = [movie, show]
        XCTAssertEqual(MediaTypeFilters.showAll.apply(to: items).count, 2)
        XCTAssertEqual(MediaTypeFilters.movies.apply(to: items).map(\.contentID), ["1@0"])
        XCTAssertEqual(MediaTypeFilters.tvShows.apply(to: items).map(\.contentID), ["2@1"])
    }

    func testHideFromUpNextPersistsAndClearsDisplayFlag() {
        let item = requireItem(for: ItemContent.examples[0].itemContentID)
        item.contentType = MediaType.tvShow.toInt
        item.displayOnUpNext = true
        item.hideFromUpNext = false
        item.watchedEpisodes = "-1@1"
        item.isWatching = true
        persistence.save()

        persistence.updateHideFromUpNext(for: item, hidden: true)
        XCTAssertTrue(item.hideFromUpNext)
        XCTAssertFalse(item.displayOnUpNext)
        XCTAssertTrue(persistence.isHiddenFromUpNext(id: item.itemContentID))

        persistence.updateHideFromUpNext(for: item, hidden: false)
        XCTAssertFalse(item.hideFromUpNext)
        XCTAssertTrue(item.displayOnUpNext)
    }

    func testHideFromUpNextBlocksRedisplayWhenWatchingEpisodes() {
        let example = ItemContent.examples.first { $0.itemContentMedia == .tvShow } ?? ItemContent.examples[0]
        let item = requireItem(for: example.itemContentID)
        item.contentType = MediaType.tvShow.toInt
        item.hideFromUpNext = true
        item.displayOnUpNext = false
        persistence.save()

        let episode = Episode(id: 99, episodeNumber: 2, seasonNumber: 1, name: "Next", runtime: 42)
        persistence.updateUpNext(item, episode: episode)
        XCTAssertTrue(item.hideFromUpNext)
        XCTAssertFalse(item.displayOnUpNext)
    }

    func testNotificationsMuteClearsPendingFlag() {
        let item = requireItem(for: ItemContent.examples[0].itemContentID)
        XCTAssertTrue(item.shouldNotify)
        persistence.updateNotificationsMuted(for: item, muted: true)
        XCTAssertFalse(item.shouldNotify)
        XCTAssertTrue(persistence.areNotificationsMuted(id: item.itemContentID))
        persistence.updateNotificationsMuted(for: item, muted: false)
        XCTAssertTrue(item.shouldNotify)
        XCTAssertFalse(persistence.areNotificationsMuted(id: item.itemContentID))
    }

    func testHideFromWatchlistPersistsSeparatelyFromArchive() {
        let item = requireItem(for: ItemContent.examples[0].itemContentID)
        item.hideFromWatchlist = false
        item.isArchive = false
        persistence.save()

        persistence.updateHideFromWatchlist(for: item, hidden: true)
        XCTAssertTrue(item.hideFromWatchlist)
        XCTAssertFalse(item.isArchive)
        XCTAssertTrue(persistence.isHiddenFromWatchlist(id: item.itemContentID))

        persistence.updateHideFromWatchlist(for: item, hidden: false)
        XCTAssertFalse(item.hideFromWatchlist)
    }

    func testSaveStoresRuntimeMinutesFromItemContent() {
        let example = ItemContent.examples[0]
        persistence.save(example)
        let item = requireItem(for: example.itemContentID)
        XCTAssertEqual(item.runtimeMinutes, example.itemRuntimeMinutes)
    }

    func testWatchStatisticsCountsWatchedAndEstimatesMovieMinutes() {
        let movie = requireItem(for: ItemContent.examples[0].itemContentID)
        movie.watched = true
        movie.watchedDate = Date()
        movie.runtimeMinutes = 120
        movie.contentType = MediaType.movie.toInt
        persistence.save()

        let stats = WatchStatistics.compute(from: [movie])
        XCTAssertEqual(stats.watchedCount, 1)
        XCTAssertEqual(stats.estimatedMinutes, 120)
        XCTAssertEqual(stats.watchedLast7Days, 1)
        XCTAssertEqual(stats.watchedLast30Days, 1)
    }

    func testRemoveWatchedEpisodesClearsProgress() {
        let item = requireItem(for: ItemContent.examples[0].itemContentID)
        item.contentType = MediaType.tvShow.toInt
        item.watchedEpisodes = "-10@1-11@1"
        item.displayOnUpNext = true
        item.isWatching = true
        persistence.save()
        XCTAssertTrue(item.hasStartedWatching)

        persistence.removeWatchedEpisodes(for: item)
        XCTAssertEqual(item.watchedEpisodes, "")
        XCTAssertFalse(item.displayOnUpNext)
        XCTAssertFalse(item.isWatching)
        XCTAssertFalse(item.hasStartedWatching)
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
