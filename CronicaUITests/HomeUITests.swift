//
//  HomeUITests.swift
//  CronicaUITests
//

import XCTest

final class HomeUITests: XCTestCase {
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

    func testTrendingSectionShowsMockContent() throws {
        navigator.openHomeTab()
        navigator.assertScreen("Home View")

        XCTAssertTrue(app.staticTexts["Trending"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["Today"].waitForExistence(timeout: 5))

        let trendingList = app.scrollViews["Trending Horizontal List"]
        XCTAssertTrue(trendingList.waitForExistence(timeout: 10))
        XCTAssertTrue(trendingList.buttons[UITestFixtures.mockMovieTitle].waitForExistence(timeout: 10))
    }
}
