import XCTest
@testable import CronicaCore

final class CronicaCoreTests: XCTestCase {
    func testMediaTypeMovieRawValue() {
        XCTAssertEqual(MediaType.movie.rawValue, "movie")
    }

    func testNetworkErrorDescriptions() {
        XCTAssertFalse(NetworkError.invalidApi.localizedName.isEmpty)
        XCTAssertFalse(NetworkError.decodingError.localizedName.isEmpty)
    }

    func testItemContentIDFormat() {
        var item = ItemContent(
            adult: nil, id: 42, title: "Test", name: nil, overview: nil, originalTitle: nil,
            posterPath: nil, backdropPath: nil, profilePath: nil, releaseDate: nil, status: nil, imdbId: nil,
            runtime: nil, numberOfEpisodes: nil, numberOfSeasons: nil, voteCount: nil,
            popularity: nil, voteAverage: nil, productionCompanies: nil, productionCountries: nil,
            seasons: nil, genres: nil, credits: nil, recommendations: nil, releaseDates: nil,
            mediaType: "movie", videos: nil, nextEpisodeToAir: nil, lastEpisodeToAir: nil,
            originalName: nil, firstAirDate: nil, homepage: nil, episodeRunTime: nil,
            placeholderImagePath: nil
        )
        XCTAssertEqual(item.itemContentID, "42@0")
        XCTAssertEqual(item.cronicaDeepLinkURL?.absoluteString, "cronica://42@0")
    }

    func testURLBuilderReturnsNilForMissingPath() {
        XCTAssertNil(NetworkService.urlBuilder(size: .w500, path: nil))
    }

    func testUITestingMockItemsDoesNotCrash() {
        XCTAssertNotNil(UITestingConfiguration.mockItems)
    }

    func testItemCalendarReleaseDateUsesTheatricalDateForMovies() {
        let releaseDate = Self.sampleDate(year: 2026, month: 8, day: 15)
        let item = Self.makeItem(
            id: 1,
            mediaType: "movie",
            releaseDate: Self.formatted(releaseDate)
        )

        XCTAssertEqual(item.itemCalendarReleaseDate, releaseDate)
    }

    func testItemCalendarReleaseDateUsesNextEpisodeDateForTVShows() {
        let episodeDate = Self.sampleDate(year: 2026, month: 9, day: 3)
        let episode = Episode(
            id: 10,
            episodeNumber: 5,
            seasonNumber: 2,
            name: "Mid-season",
            overview: nil,
            stillPath: nil,
            airDate: Self.formatted(episodeDate)
        )
        let item = Self.makeItem(id: 2, mediaType: "tv", nextEpisodeToAir: episode)

        XCTAssertEqual(item.itemCalendarReleaseDate, episodeDate)
    }

    func testItemCalendarReleaseDateFallsBackForTVShowsWithoutNextEpisode() {
        let lastAir = Self.sampleDate(year: 2024, month: 1, day: 10)
        let episode = Episode(
            id: 12,
            episodeNumber: 1,
            seasonNumber: 1,
            name: "Pilot",
            overview: nil,
            stillPath: nil,
            airDate: Self.formatted(lastAir)
        )
        let item = Self.makeItem(id: 3, mediaType: "tv", lastEpisodeToAir: episode)

        XCTAssertEqual(item.itemCalendarReleaseDate, lastAir)
    }

    func testNextEpisodeDateSupportsMidSeasonEpisodes() {
        let episodeDate = Self.sampleDate(year: 2026, month: 11, day: 20)
        let episode = Episode(
            id: 11,
            episodeNumber: 8,
            seasonNumber: 4,
            name: "Finale",
            overview: nil,
            stillPath: nil,
            airDate: Self.formatted(episodeDate)
        )
        let item = Self.makeItem(id: 4, mediaType: "tv", nextEpisodeToAir: episode)

        XCTAssertEqual(item.nextEpisodeDate, episodeDate)
        XCTAssertEqual(item.itemCalendarReleaseDate, episodeDate)
    }

    private static func makeItem(
        id: Int,
        mediaType: String,
        releaseDate: String? = nil,
        firstAirDate: String? = nil,
        nextEpisodeToAir: Episode? = nil,
        lastEpisodeToAir: Episode? = nil
    ) -> ItemContent {
        ItemContent(
            adult: nil,
            id: id,
            title: mediaType == "movie" ? "Movie \(id)" : nil,
            name: mediaType == "tv" ? "Series \(id)" : nil,
            overview: nil,
            originalTitle: nil,
            posterPath: nil,
            backdropPath: nil,
            profilePath: nil,
            releaseDate: releaseDate,
            status: nil,
            imdbId: nil,
            runtime: nil,
            numberOfEpisodes: nil,
            numberOfSeasons: nil,
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
            mediaType: mediaType,
            videos: nil,
            nextEpisodeToAir: nextEpisodeToAir,
            lastEpisodeToAir: lastEpisodeToAir,
            originalName: nil,
            firstAirDate: firstAirDate,
            homepage: nil,
            episodeRunTime: nil,
            placeholderImagePath: nil
        )
    }

    private static func sampleDate(year: Int, month: Int, day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private static func formatted(_ date: Date) -> String {
        DatesManager.dateFormatter.string(from: date)
    }
}
