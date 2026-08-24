//
//  EmptyListView.swift
//  Cronica
//

import SwiftUI

struct EmptyListView: View {
    var filter: SmartFiltersTypes? = nil
    var listTitle: String? = nil

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(description)
        }
        .padding()
        .accessibilityElement(children: .combine)
    }

    private var title: String {
        if listTitle != nil {
            return String(localized: "Nothing Here")
        }
        if let filter {
            switch filter {
            case .released: return String(localized: "Nothing Released Yet")
            case .production: return String(localized: "Nothing Upcoming")
            case .watching: return String(localized: "Nothing Watching")
            case .notWatched: return String(localized: "Nothing Unwatched")
            case .watched: return String(localized: "Nothing Watched")
            case .favorites: return String(localized: "No Favorites")
            case .pin: return String(localized: "No Pinned Items")
            case .archive: return String(localized: "Nothing Archived")
            }
        }
        return String(localized: "Your Watchlist Is Empty")
    }

    private var description: String {
        if let listTitle {
            return String(localized: "Add titles to \(listTitle) from Search or any title’s details screen.")
        }
        if filter != nil {
            return String(localized: "Try another filter, or add more titles from Search.")
        }
        return String(localized: "Open Search, find a movie or show, then tap Add to start tracking.")
    }

    private var systemImage: String {
        if let filter {
            switch filter {
            case .favorites: return "heart.slash"
            case .pin: return "pin.slash"
            case .archive: return "archivebox"
            case .watched: return "rectangle.badge.checkmark"
            case .watching: return "play.tv"
            default: return "rectangle.on.rectangle"
            }
        }
        return "rectangle.stack.badge.plus"
    }
}
