//
//  ItemContentDetailsUITests.swift
//  CronicaUITests
//

import XCTest

final class ItemContentDetailsUITests: XCTestCase {
    private var app: XCUIApplication!
    private var navigator: AppNavigator!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = AppNavigator.configuredApp(mockData: true)
        app.launch()
        navigator = AppNavigator(app: app)
        navigator.prepareForTesting()
    }

    override func tearDownWithError() throws {
        app = nil
        navigator = nil
    }

    func testDetailScreenShowsMockMetadata() throws {
        navigator.openFeaturedItem(named: UITestFixtures.mockMovieTitle)
        navigator.assertScreen("Item Content Details View")

        let title = app.staticTexts["Item Title"]
        XCTAssertTrue(title.waitForExistence(timeout: 10))
        XCTAssertEqual(title.label, UITestFixtures.mockMovieTitle)

        XCTAssertTrue(app.staticTexts["About Text"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Overview Text"].waitForExistence(timeout: 5))
    }

    func testWatchlistButtonTogglesOnDetailScreen() throws {
        navigator.openFeaturedItem(named: UITestFixtures.mockMovieTitle)
        navigator.assertScreen("Item Content Details View")

        let watchlistButton = app.buttons["Watchlist Button"]
        XCTAssertTrue(watchlistButton.waitForExistence(timeout: 10))

        let startsAsAdd = watchlistButton.label.localizedCaseInsensitiveContains("add")
        let startsAsRemove = watchlistButton.label.localizedCaseInsensitiveContains("remove")
        XCTAssertTrue(startsAsAdd || startsAsRemove)

        watchlistButton.tap()

        let firstToggleExpectation = startsAsAdd ? "remove" : "add"
        XCTAssertTrue(
            watchlistButton.waitForExistence(timeout: 5) &&
            watchlistButton.label.localizedCaseInsensitiveContains(firstToggleExpectation)
        )

        watchlistButton.tap()

        let secondToggleExpectation = startsAsAdd ? "add" : "remove"
        XCTAssertTrue(
            watchlistButton.waitForExistence(timeout: 5) &&
            watchlistButton.label.localizedCaseInsensitiveContains(secondToggleExpectation)
        )
    }
}
