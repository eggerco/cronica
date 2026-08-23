//
//  MediaType.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 28/04/22.
//

import Foundation

public enum MediaType: String, CaseIterable, Identifiable {
    public var id: String { rawValue }
    case movie, person
    case tvShow = "tv"
    public var title: String {
        switch self {
        case .movie: String(localized: "Movie")
        case .tvShow: String(localized: "TV Show")
        case .person: String(localized: "People")
        }
    }
    public var toInt: Int64 {
        switch self {
        case .movie: 0
        case .tvShow: 1
        case .person: 2
        }
    }
    public var append: String {
        switch self {
        case .movie: "credits,recommendations,release_dates,videos"
        case .person: "combined_credits,images"
        case .tvShow: "credits,recommendations,videos"
        }
    }
}


