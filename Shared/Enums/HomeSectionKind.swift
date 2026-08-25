//
//  HomeSectionKind.swift
//  Cronica
//

import Foundation

/// Built-in Home rails that can be shown, hidden, and reordered.
enum HomeSectionKind: String, CaseIterable, Codable, Identifiable, Hashable {
    case upNext
    case upcomingWatchlist
    case pins
    case favoriteLists
    case featured
    case moviesUpcoming
    case moviesNowPlaying
    case moviesPopular
    case moviesTopRated
    case tvPopular
    case tvTopRated

    var id: String { rawValue }

    var title: String {
        switch self {
        case .upNext: String(localized: "Up Next")
        case .upcomingWatchlist: String(localized: "Upcoming")
        case .pins: String(localized: "Pins")
        case .favoriteLists: String(localized: "Favorite Lists")
        case .featured: String(localized: "Featured")
        case .moviesUpcoming: String(localized: "Upcoming Movies")
        case .moviesNowPlaying: String(localized: "Latest Movies")
        case .moviesPopular: String(localized: "Popular Movies")
        case .moviesTopRated: String(localized: "Top Rated Movies")
        case .tvPopular: String(localized: "Popular TV Shows")
        case .tvTopRated: String(localized: "Top Rated TV Shows")
        }
    }

    var subtitle: String {
        switch self {
        case .upNext: String(localized: "Continue Watching")
        case .upcomingWatchlist: String(localized: "From Your Watchlist")
        case .pins: String(localized: "Pinned Titles")
        case .favoriteLists: String(localized: "Your Favorite Lists")
        case .featured: String(localized: "Popular and trending titles")
        case .moviesUpcoming: String(localized: "Coming Soon To Theaters")
        case .moviesNowPlaying: String(localized: "Recently Released")
        case .moviesPopular: String(localized: "Most Popular Right Now")
        case .moviesTopRated: String(localized: "Highest Rated")
        case .tvPopular: String(localized: "Most Popular Right Now")
        case .tvTopRated: String(localized: "Highest Rated")
        }
    }

    /// TMDB path segment when this section loads remote catalog items.
    var endpoint: Endpoints? {
        switch self {
        case .moviesUpcoming: .upcoming
        case .moviesNowPlaying: .nowPlaying
        case .moviesPopular: .popularMovies
        case .moviesTopRated: .topRatedMovies
        case .tvPopular: .popularTV
        case .tvTopRated: .topRatedTV
        default: nil
        }
    }

    static func fromPersistedRawValue(_ raw: String) -> HomeSectionKind? {
        if raw == "trending" { return .featured }
        return HomeSectionKind(rawValue: raw)
    }

    static var defaultOrder: [HomeSectionKind] {
        [
            .upNext,
            .upcomingWatchlist,
            .pins,
            .favoriteLists,
            .featured,
            .moviesUpcoming,
            .moviesNowPlaying,
            .moviesPopular,
            .moviesTopRated,
            .tvPopular,
            .tvTopRated
        ]
    }

    /// Sections enabled by default (matches historic Home before customizer).
    static var defaultVisible: Set<HomeSectionKind> {
        [.upNext, .upcomingWatchlist, .pins, .favoriteLists, .featured, .moviesUpcoming, .moviesNowPlaying]
    }
}
