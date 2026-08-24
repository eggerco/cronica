//
//  WatchlistItem+CoreDataProperties.swift
//  Cronica
//
//  Created by Alexandre Madeira on 11/03/23.
//
//

import Foundation
import CoreData


extension WatchlistItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WatchlistItem> {
        return NSFetchRequest<WatchlistItem>(entityName: "WatchlistItem")
    }

    @NSManaged public var contentID: String?
    @NSManaged public var contentType: Int64
    @NSManaged public var date: Date?
    @NSManaged public var favorite: Bool
    @NSManaged public var formattedDate: String?
    @NSManaged public var genre: String?
    @NSManaged public var id: Int64
    @NSManaged public var image: URL?
    @NSManaged public var imdbID: String?
    @NSManaged public var isArchive: Bool
    @NSManaged public var isPin: Bool
    @NSManaged public var isWatching: Bool
    @NSManaged public var largeCardImage: URL?
    @NSManaged public var largePosterImage: URL?
    @NSManaged public var lastEpisodeNumber: Int64
    @NSManaged public var lastSelectedSeason: Int64
    @NSManaged public var lastValuesUpdated: Date?
    @NSManaged public var lastWatchedEpisode: Int64
    @NSManaged public var mediumPosterImage: URL?
    @NSManaged public var nextEpisodeNumber: Int64
    @NSManaged public var nextSeasonNumber: Int64
    @NSManaged public var numberOfEpisodes: Int64
    @NSManaged public var notify: Bool
    @NSManaged public var originalTitle: String?
    @NSManaged public var schedule: Int16
    @NSManaged public var shouldNotify: Bool
    @NSManaged public var title: String?
    @NSManaged public var tmdbID: Int64
    @NSManaged public var upcomingSeason: Bool
    @NSManaged public var watched: Bool
    @NSManaged public var watchedEpisodes: String?
    @NSManaged public var list: NSSet?
    @NSManaged public var nextEpisodeNumberUpNext: Int64
    @NSManaged public var seasonNumberUpNext: Int64
    @NSManaged public var displayOnUpNext: Bool
    @NSManaged public var userNotes: String
    @NSManaged public var userRating: Int64
	@NSManaged public var posterPath: String?
	@NSManaged public var backdropPath: String?
	@NSManaged public var firstAirDate: Date?
	@NSManaged public var movieReleaseDate: Date?
}

// MARK: Generated accessors for list
extension WatchlistItem {

    @objc(addListObject:)
    @NSManaged public func addToList(_ value: CustomList)

    @objc(removeListObject:)
    @NSManaged public func removeFromList(_ value: CustomList)

    @objc(addList:)
    @NSManaged public func addToList(_ values: NSSet)

    @objc(removeList:)
    @NSManaged public func removeFromList(_ values: NSSet)

}

extension WatchlistItem : Identifiable {

}
