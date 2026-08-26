import XCTest
@testable import CronicaCore

final class TMDBURLParserTests: XCTestCase {
    func testParseMovieURL() {
        let url = URL(string: "https://www.themoviedb.org/movie/550-fight-club")!
        let reference = TMDBURLParser.parse(url)

        XCTAssertEqual(reference?.id, 550)
        XCTAssertEqual(reference?.type, .movie)
        XCTAssertEqual(reference?.contentID, "550@0")
    }

    func testParseTVURL() {
        let url = URL(string: "https://www.themoviedb.org/tv/1399-game-of-thrones")!
        let reference = TMDBURLParser.parse(url)

        XCTAssertEqual(reference?.id, 1399)
        XCTAssertEqual(reference?.type, .tvShow)
        XCTAssertEqual(reference?.contentID, "1399@1")
    }

    func testParseTVSeasonURLUsesShowID() {
        let url = URL(string: "https://www.themoviedb.org/tv/1399/season/2")!
        let reference = TMDBURLParser.parse(url)

        XCTAssertEqual(reference?.id, 1399)
        XCTAssertEqual(reference?.type, .tvShow)
    }

    func testParseCronicaDetailsURL() {
        let url = URL(string: "https://www.cronica.watch/details?id=42@0&title=Test")!
        let reference = TMDBURLParser.parse(url)

        XCTAssertEqual(reference?.id, 42)
        XCTAssertEqual(reference?.type, .movie)
    }

    func testParseContentID() {
        XCTAssertEqual(TMDBURLParser.parseContentID("550@0")?.type, .movie)
        XCTAssertEqual(TMDBURLParser.parseContentID("1399@1")?.type, .tvShow)
        XCTAssertNil(TMDBURLParser.parseContentID("invalid"))
    }

    func testRejectsUnsupportedHosts() {
        let url = URL(string: "https://example.com/movie/550")!
        XCTAssertNil(TMDBURLParser.parse(url))
    }
}
