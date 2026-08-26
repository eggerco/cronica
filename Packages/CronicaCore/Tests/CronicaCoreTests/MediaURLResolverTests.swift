import XCTest
@testable import CronicaCore

final class MediaURLResolverTests: XCTestCase {
    func testParseIMDbMovieURL() {
        let url = URL(string: "https://www.imdb.com/title/tt0137523/")!
        let hint = MediaURLResolver.parse(url)

        guard case .imdb(let id) = hint else {
            return XCTFail("Expected IMDb hint")
        }
        XCTAssertEqual(id, "tt0137523")
    }

    func testParseIMDbMobileURL() {
        let url = URL(string: "https://m.imdb.com/title/tt0137523")!
        guard case .imdb(let id) = MediaURLResolver.parse(url) else {
            return XCTFail("Expected IMDb hint")
        }
        XCTAssertEqual(id, "tt0137523")
    }

    func testParseLetterboxdFilmURL() {
        let url = URL(string: "https://letterboxd.com/film/fight-club/")!
        guard case .search(let title, let type) = MediaURLResolver.parse(url) else {
            return XCTFail("Expected search hint")
        }
        XCTAssertEqual(title, "fight club")
        XCTAssertEqual(type, .movie)
    }

    func testParseLetterboxdTVURL() {
        let url = URL(string: "https://letterboxd.com/tv/severance/")!
        guard case .search(let title, let type) = MediaURLResolver.parse(url) else {
            return XCTFail("Expected search hint")
        }
        XCTAssertEqual(title, "severance")
        XCTAssertEqual(type, .tvShow)
    }

    func testParseRottenTomatoesMovieURL() {
        let url = URL(string: "https://www.rottentomatoes.com/m/fight_club")!
        guard case .search(let title, let type) = MediaURLResolver.parse(url) else {
            return XCTFail("Expected search hint")
        }
        XCTAssertEqual(title, "fight club")
        XCTAssertEqual(type, .movie)
    }

    func testParseRottenTomatoesTVSeasonURL() {
        let url = URL(string: "https://www.rottentomatoes.com/tv/severance/s01")!
        guard case .search(let title, let type) = MediaURLResolver.parse(url) else {
            return XCTFail("Expected search hint")
        }
        XCTAssertEqual(title, "severance")
        XCTAssertEqual(type, .tvShow)
    }

    func testParseTMDBURLReturnsDirectReference() {
        let url = URL(string: "https://www.themoviedb.org/movie/550-fight-club")!
        guard case .tmdb(let reference) = MediaURLResolver.parse(url) else {
            return XCTFail("Expected direct TMDb reference")
        }
        XCTAssertEqual(reference.id, 550)
        XCTAssertEqual(reference.type, .movie)
    }

    func testTitleFromSlug() {
        XCTAssertEqual(MediaURLResolver.titleFromSlug("the-dark-knight"), "the dark knight")
        XCTAssertEqual(MediaURLResolver.titleFromSlug("fight_club"), "fight club")
    }

    func testParseTraktMovieURL() {
        let url = URL(string: "https://trakt.tv/movies/fight-club-1999")!
        guard case .search(let title, let type) = MediaURLResolver.parse(url) else {
            return XCTFail("Expected search hint")
        }
        XCTAssertEqual(title, "fight club")
        XCTAssertEqual(type, .movie)
    }

    func testParseTraktShowSeasonURL() {
        let url = URL(string: "https://trakt.tv/shows/severance/seasons/2")!
        guard case .search(let title, let type) = MediaURLResolver.parse(url) else {
            return XCTFail("Expected search hint")
        }
        XCTAssertEqual(title, "severance")
        XCTAssertEqual(type, .tvShow)
    }

    func testParseJustWatchMovieURL() {
        let url = URL(string: "https://www.justwatch.com/us/movie/fight-club")!
        guard case .search(let title, let type) = MediaURLResolver.parse(url) else {
            return XCTFail("Expected search hint")
        }
        XCTAssertEqual(title, "fight club")
        XCTAssertEqual(type, .movie)
    }

    func testParseJustWatchTVURL() {
        let url = URL(string: "https://www.justwatch.com/us/tv-show/severance")!
        guard case .search(let title, let type) = MediaURLResolver.parse(url) else {
            return XCTFail("Expected search hint")
        }
        XCTAssertEqual(title, "severance")
        XCTAssertEqual(type, .tvShow)
    }

    func testParseJustWatchLocalizedFilmURL() {
        let url = URL(string: "https://www.justwatch.com/de/Film/Fight-Club")!
        guard case .search(let title, let type) = MediaURLResolver.parse(url) else {
            return XCTFail("Expected search hint")
        }
        XCTAssertEqual(title, "Fight Club")
        XCTAssertEqual(type, .movie)
    }

    func testTraktTitleFromSlugStripsYear() {
        XCTAssertEqual(MediaURLResolver.traktTitleFromSlug("fight-club-1999"), "fight club")
        XCTAssertEqual(MediaURLResolver.traktTitleFromSlug("severance"), "severance")
    }
}
