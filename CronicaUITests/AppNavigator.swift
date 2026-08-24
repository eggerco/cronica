//
//  AppNavigator.swift
//  CronicaUITests
//

import XCTest

struct AppNavigator {
    let app: XCUIApplication

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
            screen.waitForExistence(timeout: 5),
            "Expected screen \(identifier)",
            file: file,
            line: line
        )
    }
}
