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

    func testFeaturedSectionShowsMockContent() throws {
        navigator.openHomeTab()
        navigator.assertScreen("Home View")

        XCTAssertTrue(app.staticTexts["Featured"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["Popular and trending titles"].waitForExistence(timeout: 5))

        let featuredList = app.scrollViews["Featured Horizontal List"]
        XCTAssertTrue(featuredList.waitForExistence(timeout: 10))
        XCTAssertTrue(featuredList.buttons[UITestFixtures.mockMovieTitle].waitForExistence(timeout: 10))
    }
}
