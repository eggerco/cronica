//
//  AppNavigator.swift
//  CronicaUITests
//

import XCTest

struct AppNavigator {
    let app: XCUIApplication

    static func configuredApp(mockData: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        if mockData {
            app.launchArguments.append("--mock-data")
        }
        return app
    }

    func prepareForTesting() {
        dismissWelcomeScreenIfNeeded()
    }

    func dismissWelcomeScreenIfNeeded() {
        let continueButton = app.buttons["Continue"]
        if continueButton.waitForExistence(timeout: 2) {
            continueButton.tap()
        }
    }

    func tapTab(_ name: String) {
        let tab = app.tabBars.buttons[name]
        XCTAssertTrue(tab.waitForExistence(timeout: 10), "Missing tab: \(name)")
        tab.tap()
    }

    func openHomeTab() {
        tapTab("Home")
    }

    func openDiscoverTab() {
        tapTab("Discover")
    }

    func openWatchlistTab() {
        tapTab("Watchlist")
    }

    func openSearchTab() {
        tapTab("Search")
    }

    func openSettingsFromHome() {
        openHomeTab()
        let settings = app.buttons["Settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 5))
        settings.tap()
    }

    func openNotificationsFromHome() {
        openHomeTab()
        let notifications = app.buttons["Notifications"]
        XCTAssertTrue(notifications.waitForExistence(timeout: 5))
        notifications.tap()
    }

    func assertScreen(_ identifier: String, file: StaticString = #filePath, line: UInt = #line) {
        let screen = app.otherElements[identifier]
        XCTAssertTrue(
            screen.waitForExistence(timeout: 10),
            "Expected screen \(identifier)",
            file: file,
            line: line
        )
    }

    func openFeaturedItem(named title: String, file: StaticString = #filePath, line: UInt = #line) {
        openHomeTab()
        XCTAssertTrue(app.staticTexts["Featured"].waitForExistence(timeout: 15), file: file, line: line)

        let featuredList = app.scrollViews["Featured Horizontal List"]
        XCTAssertTrue(featuredList.waitForExistence(timeout: 10), file: file, line: line)

        let itemButton = featuredList.buttons[title]
        if itemButton.waitForExistence(timeout: 5) {
            itemButton.tap()
            return
        }

        for _ in 0..<4 {
            featuredList.swipeLeft()
            if itemButton.waitForExistence(timeout: 1) {
                itemButton.tap()
                return
            }
        }

        XCTFail("Could not find featured item \(title)", file: file, line: line)
    }
}

enum UITestFixtures {
    static let mockMovieTitle = "Zack Snyder's Justice League"
}
