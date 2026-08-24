//
//  SettingsUITests.swift
//  CronicaUITests
//

import XCTest

final class SettingsUITests: XCTestCase {
    private var app: XCUIApplication!
    private var navigator: AppNavigator!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = AppNavigator.configuredApp()
        app.launch()
        navigator = AppNavigator(app: app)
        navigator.prepareForTesting()
    }

    override func tearDownWithError() throws {
        app = nil
        navigator = nil
    }

    func testSettingsShowsCoreSections() throws {
        navigator.openSettingsFromHome()
        navigator.assertScreen("Settings View")
        XCTAssertTrue(app.staticTexts["Appearance"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Notifications"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Watchlist"].waitForExistence(timeout: 5))
    }
}
