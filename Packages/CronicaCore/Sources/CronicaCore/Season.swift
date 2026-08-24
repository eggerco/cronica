//
//  Season.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 28/04/22.
//

import Foundation
import SwiftUI

/// A model that represents a TV Show's season.
public struct Season: Codable, Identifiable, Hashable {
    public let id, seasonNumber: Int
    public let name, overview: String?
    public let episodes: [Episode]?
    public let airDate: String?
    public let posterPath: String?
}
/// A model that represents an episode.
public struct Episode: Identifiable, Codable, Hashable {
    public let id: Int
    public let episodeNumber, seasonNumber: Int?
    public let name, overview, stillPath, airDate: String?

    public init(
        id: Int,
        episodeNumber: Int? = nil,
        seasonNumber: Int? = nil,
        name: String? = nil,
        overview: String? = nil,
        stillPath: String? = nil,
        airDate: String? = nil
    ) {
        self.id = id
        self.episodeNumber = episodeNumber
        self.seasonNumber = seasonNumber
        self.name = name
        self.overview = overview
        self.stillPath = stillPath
        self.airDate = airDate
    }
}

public extension Season {
    var seasonPosterUrl: URL? {
        return NetworkService.urlBuilder(size: .medium, path: posterPath)
    }
    
    var itemDate: String? {
        if let airDate, let date = airDate.toDate() {
            return date.convertDateToString()
        }
        return nil
    }
}
