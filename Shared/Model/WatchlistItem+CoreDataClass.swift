//
//  WatchlistItem+CoreDataClass.swift
//  Cronica
//
//  Created by Alexandre Madeira on 11/03/23.
//
//

import Foundation
import CoreData

@objc(WatchlistItem)
public class WatchlistItem: NSManagedObject, Codable {
    required convenience public init(from decoder: Decoder) throws {
        guard let context = decoder.userInfo[.context] as? NSManagedObjectContext else {
            throw ContextError.NoContextFound
        }
        self.init(context: context)
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int64.self, forKey: .id)
        title = try values.decode(String.self, forKey: .title)
        contentID = try values.decode(String.self, forKey: .contentID)
        image = try values.decodeIfPresent(URL.self, forKey: .image)
        watchedEpisodes = try values.decodeIfPresent(String.self, forKey: .watchedEpisodes) ?? ""
        watched = try values.decodeIfPresent(Bool.self, forKey: .watched) ?? false
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
    }
    
    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(title, forKey: .title)
        try values.encode(contentID, forKey: .contentID)
        try values.encode(id, forKey: .id)
        try values.encode(image, forKey: .image)
        try values.encode(watchedEpisodes, forKey: .watchedEpisodes)
        try values.encode(watched, forKey: .watched)
        try values.encode(favorite, forKey: .favorite)
        try values.encode(contentType, forKey: .contentType)
        try values.encode(schedule, forKey: .schedule)
        try values.encode(largeCardImage, forKey: .largeCardImage)
        try values.encode(largePosterImage, forKey: .largePosterImage)
        try values.encode(mediumPosterImage, forKey: .mediumPosterImage)
        try values.encode(shouldNotify, forKey: .shouldNotify)
        try values.encode(isArchive, forKey: .isArchive)
        try values.encode(nextEpisodeNumber, forKey: .nextEpisodeNumber)
        try values.encode(nextSeasonNumber, forKey: .nextSeasonNumber)
        try values.encode(nextEpisodeNumberUpNext, forKey: .nextEpisodeNumberUpNext)
        try values.encode(seasonNumberUpNext, forKey: .seasonNumberUpNext)
        try values.encode(displayOnUpNext, forKey: .displayOnUpNext)
        try values.encode(isPin, forKey: .isPin)
        try values.encode(lastEpisodeNumber, forKey: .lastEpisodeNumber)
        try values.encode(lastSelectedSeason, forKey: .lastSelectedSeason)
        try values.encode(userNotes, forKey: .userNotes)
        try values.encode(userRating, forKey: .userRating)
        try values.encode(isWatching, forKey: .isWatching)
		try values.encode(posterPath, forKey: .posterPath)
		try values.encode(backdropPath, forKey: .backdropPath)
		try values.encode(firstAirDate, forKey: .firstAirDate)
		try values.encode(movieReleaseDate, forKey: .movieReleaseDate)
    }
    
    enum CodingKeys: CodingKey {
        case title, contentID, id, image, watchedEpisodes, watched, favorite, contentType,
             schedule, largeCardImage, largePosterImage, mediumPosterImage, shouldNotify,
             isArchive, nextEpisodeNumber, nextSeasonNumber, nextEpisodeNumberUpNext,
             seasonNumberUpNext, displayOnUpNext, isPin, lastEpisodeNumber, lastSelectedSeason,
             userNotes, userRating, isWatching, posterPath, backdropPath, firstAirDate, movieReleaseDate
    }
}

extension CodingUserInfoKey {
    static let context = CodingUserInfoKey(rawValue: "managedObjectContext")!
}

enum ContextError: Error {
    case NoContextFound
}
