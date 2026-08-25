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
    public var sortIndex: Int {
        switch self {
        case .upcoming: return 0
        case .nowPlaying: return 1
        }
    }
    public var title: String {
        switch self {
        case .upcoming: return String(localized: "Upcoming", bundle: .main)
        case .nowPlaying: return String(localized: "Latest Movies", bundle: .main)
        }
    }
    public var subtitle: String {
        switch self {
        case .upcoming: return String(localized: "Coming Soon To Theaters", bundle: .main)
        case .nowPlaying: return String(localized: "Recently Released", bundle: .main)
        }
    }
    public var type: MediaType {
        switch self {
        case .upcoming: return .movie
        case .nowPlaying: return .movie
        }
    }
}
