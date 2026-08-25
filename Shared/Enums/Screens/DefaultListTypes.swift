//
//  SmartFiltersTypes.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 10/08/22.
//
import Foundation

/// The type of lists supported by WatchlistView.
///
/// This value is used to provide filter functionality for WatchlistView.
enum SmartFiltersTypes: String, Identifiable, Hashable, CaseIterable {
    var id: String { rawValue }
    case released, production, watching, notWatched, watched, favorites, pin, archive
    var title: String {
        switch self {
        case .released:
            return String(localized: "Released")
        case .production:
            return String(localized: "Upcoming")
        case .watched:
            return String(localized: "Watched")
        case .favorites:
            return String(localized: "Favorites")
        case .pin:
            return String(localized: "Pins")
        case .archive:
            return String(localized: "Archive")
        case .watching:
            return String(localized: "Watching")
        case .notWatched:
            return String(localized: "Unwatched")
        }
    }
}
