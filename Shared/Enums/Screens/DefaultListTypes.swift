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
    /// Order matches the watchlist funnel: released/upcoming, then to-watch → watching → watched.
    case released, production, notWatched, watching, watched, favorites, pin, archive
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
            return String(localized: "To Watch")
        }
    }

    /// Single source of truth for smart-filter membership (iOS, macOS, watchOS).
    ///
    /// Released is checklist-style: schedule-released and not finished. Marking Watched
    /// moves a title out of Released / To Watch and into Watched.
    func matches(_ item: WatchlistItem) -> Bool {
        switch self {
        case .released:
            return item.isReleased && !item.isWatched
        case .production:
            return item.isInProduction || item.isUpcoming
        case .watching:
            return item.isCurrentlyWatching
        case .watched:
            return item.isWatched
        case .favorites:
            return item.isFavorite
        case .pin:
            return item.isPin
        case .archive:
            return item.isArchive
        case .notWatched:
            return !item.isCurrentlyWatching && !item.isWatched && item.isReleased
        }
    }
}
