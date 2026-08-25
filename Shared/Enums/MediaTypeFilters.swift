//
//  MediaTypeFilters.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 06/04/23.
//

import Foundation

enum MediaTypeFilters: String, Identifiable, CaseIterable {
    var id: String { rawValue }
    case showAll, movies, tvShows
    var localizableTitle: String {
        switch self {
        case .showAll: String(localized: "All")
        case .movies: String(localized: "Movies")
        case .tvShows: String(localized: "TV Shows")
        }
    }

    /// Filters watchlist items by media type. `.showAll` returns the input unchanged.
    func apply(to items: [WatchlistItem]) -> [WatchlistItem] {
        switch self {
        case .showAll: items
        case .movies: items.filter(\.isMovie)
        case .tvShows: items.filter(\.isTvShow)
        }
    }
}
