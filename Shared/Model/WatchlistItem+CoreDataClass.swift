//
//  WatchlistItem+CoreDataClass.swift
//  Cronica
//
//  Created by Alexandre Madeira on 11/03/23.
//
//

import Foundation
import CoreData
import CronicaCore

@objc(WatchlistItem)
public class WatchlistItem: NSManagedObject, Codable {
    required convenience public init(from decoder: Decoder) throws {
        guard let context = decoder.userInfo[.context] as? NSManagedObjectContext else {
            throw ContextError.NoContextFound
        }
        self.init(context: context)
        
        do {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            id = try values.decode(Int64.self, forKey: .id)
            title = try values.decode(String.self, forKey: .title)
            contentID = try values.decode(String.self, forKey: .contentID)
            image = try values.decode(URL?.self, forKey: .image)
            watchedEpisodes = try values.decode(String.self, forKey: .watchedEpisodes)
            watched = try values.decode(Bool.self, forKey: .watched)
            favorite = try values.decode(Bool.self, forKey: .favorite)
            contentType = try values.decode(Int64.self, forKey: .contentType)
            schedule = try values.decode(Int16.self, forKey: .schedule)
            largeCardImage = try values.decode(URL?.self, forKey: .largeCardImage)
            largePosterImage = try values.decode(URL?.self, forKey: .largePosterImage)
            mediumPosterImage = try values.decode(URL?.self, forKey: .mediumPosterImage)
            shouldNotify = try values.decode(Bool.self, forKey: .shouldNotify)
            isArchive = try values.decode(Bool.self, forKey: .isArchive)
            nextEpisodeNumber = try values.decode(Int64.self, forKey: .nextEpisodeNumber)
            nextSeasonNumber = try values.decode(Int64.self, forKey: .nextSeasonNumber)
            nextEpisodeNumberUpNext = try values.decode(Int64.self, forKey: .nextEpisodeNumberUpNext)
            seasonNumberUpNext = try values.decode(Int64.self, forKey: .seasonNumberUpNext)
            displayOnUpNext = try values.decode(Bool.self, forKey: .displayOnUpNext)
            isPin = try values.decode(Bool.self, forKey: .isPin)
            lastEpisodeNumber = try values.decode(Int64.self, forKey: .lastEpisodeNumber)
            lastSelectedSeason = try values.decode(Int64.self, forKey: .lastSelectedSeason)
            userNotes = try values.decode(String.self, forKey: .userNotes)
            userRating = try values.decode(Int64.self, forKey: .userRating)
            isWatching = try values.decode(Bool.self, forKey: .isWatching)
			posterPath = try values.decode(String?.self, forKey: .posterPath)
			backdropPath = try values.decode(String?.self, forKey: .backdropPath)
			firstAirDate = try values.decode(Date?.self, forKey: .firstAirDate)
			movieReleaseDate = try values.decode(Date?.self, forKey: .movieReleaseDate)
        } catch {
            AppLogger.persistence.error("Failed to decode WatchlistItem: \(error.localizedDescription)")
            throw error
        }
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
