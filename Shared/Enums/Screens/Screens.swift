//
//  Screens.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 28/04/22.
//

import Foundation
#if !os(watchOS)
enum Screens: String, Identifiable, CaseIterable {
    var id: String { rawValue }
    case home, explore, watchlist, search, notifications
#if os(iOS) || os(tvOS) || os(visionOS)
    case settings
#endif
    
    var title: String {
        switch self {
        case .home: String(localized: "Home")
        case .explore: String(localized: "Explore")
        case .watchlist: String(localized: "Watchlist")
        case .search: String(localized: "Search")
#if os(iOS) || os(tvOS) || os(visionOS)
        case .settings: String(localized: "Settings")
#endif
        case .notifications: String(localized: "Notifications")
        }
    }
}
#else
enum Screens: String, Identifiable, CaseIterable {
    var id: String { rawValue }
    case trending, watchlist, upNext, upcoming
    
    var title: String {
        switch self {
        case .trending: String(localized: "Trending")
        case .watchlist: String(localized: "Watchlist")
        case .upcoming: String(localized: "Upcoming")
        case .upNext: String(localized: "Up Next")
        }
    }
    var toSFSymbols: String {
        switch self {
        case .trending: "popcorn"
        case .watchlist: "rectangle.on.rectangle"
        case .upcoming: "calendar"
        case .upNext: "tv"
        }
    }
}
#endif
