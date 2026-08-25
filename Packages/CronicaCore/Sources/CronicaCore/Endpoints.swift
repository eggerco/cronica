//
//  Endpoints.swift
//  Cronica
//
//  Created by Alexandre Madeira on 28/01/22.
//

import Foundation

/// Endpoints represents a default list that can be fetched from TMDb.
public enum Endpoints: String, CaseIterable, Identifiable, Sendable {
    public var id: String { rawValue }
    case upcoming
    case nowPlaying = "now_playing"
    case popularMovies = "popular"
    case topRatedMovies = "top_rated"
    case popularTV = "tv_popular"
    case topRatedTV = "tv_top_rated"

    /// Path used with TMDB: `/{media}/{list}` (custom raw values remapped below).
    public var path: String {
        switch self {
        case .popularTV: return "\(MediaType.tvShow.rawValue)/popular"
        case .topRatedTV: return "\(MediaType.tvShow.rawValue)/top_rated"
        default: return "\(type.rawValue)/\(rawValue)"
        }
    }

    public var sortIndex: Int {
        switch self {
        case .upcoming: return 0
        case .nowPlaying: return 1
        case .popularMovies: return 2
        case .topRatedMovies: return 3
        case .popularTV: return 4
        case .topRatedTV: return 5
        }
    }
    public var title: String {
        switch self {
        case .upcoming: return String(localized: "Upcoming Movies", bundle: .main)
        case .nowPlaying: return String(localized: "Latest Movies", bundle: .main)
        case .popularMovies: return String(localized: "Popular Movies", bundle: .main)
        case .topRatedMovies: return String(localized: "Top Rated Movies", bundle: .main)
        case .popularTV: return String(localized: "Popular TV Shows", bundle: .main)
        case .topRatedTV: return String(localized: "Top Rated TV Shows", bundle: .main)
        }
    }
    public var subtitle: String {
        switch self {
        case .upcoming: return String(localized: "Coming Soon To Theaters", bundle: .main)
        case .nowPlaying: return String(localized: "Recently Released", bundle: .main)
        case .popularMovies, .popularTV: return String(localized: "Most Popular Right Now", bundle: .main)
        case .topRatedMovies, .topRatedTV: return String(localized: "Highest Rated", bundle: .main)
        }
    }
    public var type: MediaType {
        switch self {
        case .upcoming, .nowPlaying, .popularMovies, .topRatedMovies: return .movie
        case .popularTV, .topRatedTV: return .tvShow
        }
    }
}
