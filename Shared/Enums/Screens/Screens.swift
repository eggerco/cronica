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
        case .home: NSLocalizedString("Home", comment: "")
        case .explore: NSLocalizedString("Discover", comment: "")
        case .watchlist: NSLocalizedString("Watchlist", comment: "")
        case .search: NSLocalizedString("Search", comment: "")
#if os(iOS) || os(tvOS) || os(visionOS)
        case .settings: NSLocalizedString("Settings", comment: "")
#endif
        case .notifications: NSLocalizedString("Notifications", comment: "")
        }
    }
}
#else
enum Screens: String, Identifiable, CaseIterable {
    var id: String { rawValue }
    case trending, watchlist, upNext, upcoming
    
    var title: String {
        switch self {
        case .trending: NSLocalizedString("Trending", comment: "")
        case .watchlist: NSLocalizedString("Watchlist", comment: "")
        case .upcoming: NSLocalizedString("Upcoming", comment: "")
        case .upNext: NSLocalizedString("Up Next", comment: "")
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
