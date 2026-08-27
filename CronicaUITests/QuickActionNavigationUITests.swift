//
//  QuickActionNavigationUITests.swift
//  CronicaUITests
//

import XCTest

final class QuickActionNavigationUITests: XCTestCase {
    private let quickActionLaunchKey = "-ui-test-quick-action"

    func testSearchQuickActionOpensSearchTab() {
        let app = AppNavigator.configuredApp()
        app.launchArguments.append(contentsOf: [quickActionLaunchKey, "search"])
        app.launch()

        let navigator = AppNavigator(app: app)
        navigator.prepareForTesting()
        navigator.assertScreen("Search View")
    }

    func testWatchlistQuickActionOpensWatchlistTab() {
        let app = AppNavigator.configuredApp()
        app.launchArguments.append(contentsOf: [quickActionLaunchKey, "watchlist"])
        app.launch()

        let navigator = AppNavigator(app: app)
        navigator.prepareForTesting()
        navigator.assertScreen("Watchlist View")
    }
}
