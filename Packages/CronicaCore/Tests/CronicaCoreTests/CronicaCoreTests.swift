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
            widgetImageData: nil, placeholderImagePath: nil
        )
        XCTAssertEqual(item.itemContentID, "42@0")
    }

    func testURLBuilderReturnsNilForMissingPath() {
        XCTAssertNil(NetworkService.urlBuilder(size: .w500, path: nil))
    }
}
