import XCTest

final class CronicaUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchShowsHomeScreen() throws {
        let app = XCUIApplication()
        app.launch()

        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 10))
        homeTab.tap()

        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 5))
    }

    func testWatchlistTabIsReachable() throws {
        let app = XCUIApplication()
        app.launch()

        let watchlistTab = app.tabBars.buttons["Watchlist"]
        XCTAssertTrue(watchlistTab.waitForExistence(timeout: 10))
        watchlistTab.tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 5))
    }
}
