//
//  CronicaUITests.swift
//  CronicaUITests
//

import XCTest

final class CronicaUITests: XCTestCase {
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

    func testHomeTabShowsHomeScreen() throws {
        navigator.openHomeTab()
        navigator.assertScreen("Home View")
    }

    func testDiscoverTabShowsDiscoverScreen() throws {
        navigator.openDiscoverTab()
        navigator.assertScreen("Discover View")
    }

    func testWatchlistTabShowsWatchlistScreen() throws {
        navigator.openWatchlistTab()
        navigator.assertScreen("Watchlist View")
    }

    func testSearchTabShowsSearchScreen() throws {
        navigator.openSearchTab()
        navigator.assertScreen("Search View")
    }

    func testHomeToolbarOpensSettings() throws {
        navigator.openSettingsFromHome()
        navigator.assertScreen("Settings View")
    }

    func testHomeToolbarOpensNotifications() throws {
        navigator.openNotificationsFromHome()
        navigator.assertScreen("Notification List View")
    }
}
