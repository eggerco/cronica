//
//  Endpoints.swift
//  Cronica
//
//  Created by Alexandre Madeira on 28/01/22.
//

import Foundation

/// Endpoints represents a default list that can be fetched from TMDb.
public enum Endpoints: String, CaseIterable, Identifiable {
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
        case .upcoming: return NSLocalizedString("Up Coming", comment: "")
        case .nowPlaying: return NSLocalizedString("Latest Movies", comment: "")
        }
    }
    public var subtitle: String {
        switch self {
        case .upcoming: return NSLocalizedString("Coming Soon To Theaters", comment: "")
        case .nowPlaying: return NSLocalizedString("Recently Released", comment: "")
        }
    }
    public var type: MediaType {
        switch self {
        case .upcoming: return .movie
        case .nowPlaying: return .movie
        }
    }
}
