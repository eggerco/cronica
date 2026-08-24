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

    public init(
        adult: Bool?, id: Int, title: String?, name: String?, overview: String?, originalTitle: String?,
        posterPath: String?, backdropPath: String?, profilePath: String?, releaseDate: String?, status: String?, imdbId: String?,
        runtime: Int?, numberOfEpisodes: Int?, numberOfSeasons: Int?, voteCount: Int?,
        popularity: Double?, voteAverage: Double?, productionCompanies: [ProductionCompany]?, productionCountries: [ProductionCountry]?,
        seasons: [Season]?, genres: [Genre]?, credits: Credits?, recommendations: ItemContentResponse?, releaseDates: ReleaseDates?,
        mediaType: String?, videos: Videos?, nextEpisodeToAir: Episode?, lastEpisodeToAir: Episode?,
        originalName: String?, firstAirDate: String?, homepage: String?, episodeRunTime: [Int]?,
        widgetImageData: Data?, placeholderImagePath: String?
    ) {
        self.adult = adult
        self.id = id
        self.title = title
        self.name = name
        self.overview = overview
        self.originalTitle = originalTitle
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.profilePath = profilePath
        self.releaseDate = releaseDate
        self.status = status
        self.imdbId = imdbId
        self.runtime = runtime
        self.numberOfEpisodes = numberOfEpisodes
        self.numberOfSeasons = numberOfSeasons
        self.voteCount = voteCount
        self.popularity = popularity
        self.voteAverage = voteAverage
        self.productionCompanies = productionCompanies
        self.productionCountries = productionCountries
        self.seasons = seasons
        self.genres = genres
        self.credits = credits
        self.recommendations = recommendations
        self.releaseDates = releaseDates
        self.mediaType = mediaType
        self.videos = videos
        self.nextEpisodeToAir = nextEpisodeToAir
        self.lastEpisodeToAir = lastEpisodeToAir
        self.originalName = originalName
        self.firstAirDate = firstAirDate
        self.homepage = homepage
        self.episodeRunTime = episodeRunTime
        self.widgetImageData = widgetImageData
        self.placeholderImagePath = placeholderImagePath
    }

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

    public init(name: String, id: Int, logoPath: String?, originCountry: String?, description: String?) {
        self.name = name
        self.id = id
        self.logoPath = logoPath
        self.originCountry = originCountry
        self.description = description
    }
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

    public init(id: Int, name: String?) {
        self.id = id
        self.name = name
    }
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
