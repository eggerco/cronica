//
//  ItemContent.swift
//  Cronica
//
//  Created by Alexandre Madeira on 17/02/22.
//

import Foundation

/// A model that represents a movie or tv show.
///
/// it is also used for people only on multi search results.
public struct ItemContent: Identifiable, Codable, Hashable, Sendable {
    public let adult: Bool?
    public let id: Int
    public let title, name, overview, originalTitle: String?
    public let posterPath, backdropPath, profilePath: String?
    public let releaseDate, status, imdbId: String?
    public let runtime, numberOfEpisodes, numberOfSeasons, voteCount: Int?
    public let popularity, voteAverage: Double?
    public let productionCompanies: [ProductionCompany]?
    public let productionCountries: [ProductionCountry]?
    public let seasons: [Season]?
    public let genres: [Genre]?
    public let credits: Credits?
    public let recommendations: ItemContentResponse?
    public let releaseDates: ReleaseDates?
    public let mediaType: String?
    public var videos: Videos?
    public var nextEpisodeToAir, lastEpisodeToAir: Episode?
    public let originalName, firstAirDate, homepage: String?
    public let episodeRunTime: [Int]?
    /// Cached image bytes used by the widget extension.
    public var widgetImageData: Data?
    /// Asset catalog placeholder key used by the widget extension.
    public var placeholderImagePath: String?

    enum CodingKeys: String, CodingKey {
        case adult, id, title, name, overview, originalTitle
        case posterPath, backdropPath, profilePath
        case releaseDate, status, imdbId
        case runtime, numberOfEpisodes, numberOfSeasons, voteCount
        case popularity, voteAverage
        case productionCompanies, productionCountries, seasons, genres, credits
        case recommendations, releaseDates, mediaType, videos
        case nextEpisodeToAir, lastEpisodeToAir
        case originalName, firstAirDate, homepage, episodeRunTime
    }
}
public struct ProductionCompany: Identifiable, Codable, Hashable {
    public let name: String
    public let id: Int
    public let logoPath: String?
    public let originCountry: String?
    public let description: String?
}
public extension ProductionCompany {
    var logoUrl: URL? {
        return NetworkService.urlBuilder(size: .medium, path: logoPath)
    }
}
public struct ProductionCountry: Codable, Hashable {
	public let iso31661: String
    public let name: String
}
public struct Genre: Codable, Identifiable, Hashable {
    public let id: Int
    public let name: String?
}

public extension Genre {
    public var isGenreAvailable: Bool {
        if name != nil { return true }
        return false
    }
    public var itemTitle: String {
        name ?? NSLocalizedString("Not Found", comment: "")
    }
}

public struct ItemContentResponse: Identifiable, Codable, Hashable {
    public let id: String?
    public let results: [ItemContent]
}

public struct ItemContentKeyword: Identifiable, Codable, Hashable {
    public let id: Int
	public let name: String?
}

public struct Keywords: Hashable, Codable {
    public let keywords: [ItemContentKeyword]
}
