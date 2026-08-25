//
//  WatchlistItemBackup.swift
//  Cronica
//

import Foundation
import CoreData

/// Codable transfer model for watchlist backup/restore.
/// Kept separate from `WatchlistItem` so restore can upsert by `contentID` without duplicating rows.
struct WatchlistItemBackup: Codable, Equatable {
    var id: Int64
    var title: String
    var contentID: String
    var image: URL?
    var watchedEpisodes: String
    var watched: Bool
    var watchedDate: Date?
    var favorite: Bool
    var contentType: Int64
    var schedule: Int16
    var largeCardImage: URL?
    var largePosterImage: URL?
    var mediumPosterImage: URL?
    var shouldNotify: Bool
    var isArchive: Bool
    var nextEpisodeNumber: Int64
    var nextSeasonNumber: Int64
    var nextEpisodeNumberUpNext: Int64
    var seasonNumberUpNext: Int64
    var displayOnUpNext: Bool
    var isPin: Bool
    var lastEpisodeNumber: Int64
    var lastSelectedSeason: Int64
    var userNotes: String
    var userRating: Int64
    var isWatching: Bool
    var posterPath: String?
    var backdropPath: String?
    var firstAirDate: Date?
    var movieReleaseDate: Date?
    var numberOfEpisodes: Int64

    init(item: WatchlistItem) {
        id = item.id
        title = item.title ?? ""
        contentID = item.contentID ?? ""
        image = item.image
        watchedEpisodes = item.watchedEpisodes ?? ""
        watched = item.watched
        watchedDate = item.watchedDate
        favorite = item.favorite
        contentType = item.contentType
        schedule = item.schedule
        largeCardImage = item.largeCardImage
        largePosterImage = item.largePosterImage
        mediumPosterImage = item.mediumPosterImage
        shouldNotify = item.shouldNotify
        isArchive = item.isArchive
        nextEpisodeNumber = item.nextEpisodeNumber
        nextSeasonNumber = item.nextSeasonNumber
        nextEpisodeNumberUpNext = item.nextEpisodeNumberUpNext
        seasonNumberUpNext = item.seasonNumberUpNext
        displayOnUpNext = item.displayOnUpNext
        isPin = item.isPin
        lastEpisodeNumber = item.lastEpisodeNumber
        lastSelectedSeason = item.lastSelectedSeason
        userNotes = item.userNotes ?? ""
        userRating = item.userRating
        isWatching = item.isWatching
        posterPath = item.posterPath
        backdropPath = item.backdropPath
        firstAirDate = item.firstAirDate
        movieReleaseDate = item.movieReleaseDate
        numberOfEpisodes = item.numberOfEpisodes
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int64.self, forKey: .id)
        title = try values.decodeIfPresent(String.self, forKey: .title) ?? ""
        contentID = try values.decode(String.self, forKey: .contentID)
        image = try values.decodeIfPresent(URL.self, forKey: .image)
        watchedEpisodes = try values.decodeIfPresent(String.self, forKey: .watchedEpisodes) ?? ""
        watched = try values.decodeIfPresent(Bool.self, forKey: .watched) ?? false
        watchedDate = try values.decodeIfPresent(Date.self, forKey: .watchedDate)
        favorite = try values.decodeIfPresent(Bool.self, forKey: .favorite) ?? false
        contentType = try values.decode(Int64.self, forKey: .contentType)
        schedule = try values.decodeIfPresent(Int16.self, forKey: .schedule) ?? 0
        largeCardImage = try values.decodeIfPresent(URL.self, forKey: .largeCardImage)
        largePosterImage = try values.decodeIfPresent(URL.self, forKey: .largePosterImage)
        mediumPosterImage = try values.decodeIfPresent(URL.self, forKey: .mediumPosterImage)
        shouldNotify = try values.decodeIfPresent(Bool.self, forKey: .shouldNotify) ?? false
        isArchive = try values.decodeIfPresent(Bool.self, forKey: .isArchive) ?? false
        nextEpisodeNumber = try values.decodeIfPresent(Int64.self, forKey: .nextEpisodeNumber) ?? 0
        nextSeasonNumber = try values.decodeIfPresent(Int64.self, forKey: .nextSeasonNumber) ?? 0
        nextEpisodeNumberUpNext = try values.decodeIfPresent(Int64.self, forKey: .nextEpisodeNumberUpNext) ?? 0
        seasonNumberUpNext = try values.decodeIfPresent(Int64.self, forKey: .seasonNumberUpNext) ?? 0
        displayOnUpNext = try values.decodeIfPresent(Bool.self, forKey: .displayOnUpNext) ?? false
        isPin = try values.decodeIfPresent(Bool.self, forKey: .isPin) ?? false
        lastEpisodeNumber = try values.decodeIfPresent(Int64.self, forKey: .lastEpisodeNumber) ?? 0
        lastSelectedSeason = try values.decodeIfPresent(Int64.self, forKey: .lastSelectedSeason) ?? 0
        userNotes = try values.decodeIfPresent(String.self, forKey: .userNotes) ?? ""
        userRating = try values.decodeIfPresent(Int64.self, forKey: .userRating) ?? 0
        isWatching = try values.decodeIfPresent(Bool.self, forKey: .isWatching) ?? false
        posterPath = try values.decodeIfPresent(String.self, forKey: .posterPath)
        backdropPath = try values.decodeIfPresent(String.self, forKey: .backdropPath)
        firstAirDate = try values.decodeIfPresent(Date.self, forKey: .firstAirDate)
        movieReleaseDate = try values.decodeIfPresent(Date.self, forKey: .movieReleaseDate)
        numberOfEpisodes = try values.decodeIfPresent(Int64.self, forKey: .numberOfEpisodes) ?? 0
    }
}

extension WatchlistItem {
    func apply(_ backup: WatchlistItemBackup) {
        id = backup.id
        title = backup.title
        contentID = backup.contentID
        image = backup.image
        watchedEpisodes = backup.watchedEpisodes
        watched = backup.watched
        watchedDate = backup.watchedDate
        favorite = backup.favorite
        contentType = backup.contentType
        schedule = backup.schedule
        largeCardImage = backup.largeCardImage
        largePosterImage = backup.largePosterImage
        mediumPosterImage = backup.mediumPosterImage
        shouldNotify = backup.shouldNotify
        isArchive = backup.isArchive
        nextEpisodeNumber = backup.nextEpisodeNumber
        nextSeasonNumber = backup.nextSeasonNumber
        nextEpisodeNumberUpNext = backup.nextEpisodeNumberUpNext
        seasonNumberUpNext = backup.seasonNumberUpNext
        displayOnUpNext = backup.displayOnUpNext
        isPin = backup.isPin
        lastEpisodeNumber = backup.lastEpisodeNumber
        lastSelectedSeason = backup.lastSelectedSeason
        userNotes = backup.userNotes
        userRating = backup.userRating
        isWatching = backup.isWatching
        posterPath = backup.posterPath
        backdropPath = backup.backdropPath
        firstAirDate = backup.firstAirDate
        movieReleaseDate = backup.movieReleaseDate
        numberOfEpisodes = backup.numberOfEpisodes
    }
}
