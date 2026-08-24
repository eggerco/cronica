//
//  WatchlistItem-CoreDataHelpers.swift
//  Cronica
//
//  Created by Alexandre Madeira on 15/02/22.
//

import Foundation
import CoreData

extension WatchlistItem {
	var itemTitle: String {
		title ?? NSLocalizedString("No title available", comment: "")
	}
	var itemOriginalTitle: String {
		originalTitle ?? NSLocalizedString("No title available", comment: "")
	}
	var itemLastUpdateDate: Date {
		lastValuesUpdated ?? Date.distantPast
	}
	var watchedEpisodeCount: Int {
		guard let watchedEpisodes, !watchedEpisodes.isEmpty else { return 0 }
		return watchedEpisodes
			.split(separator: "-", omittingEmptySubsequences: true)
			.filter { $0.contains("@") }
			.count
	}
	var hasStartedWatching: Bool {
		isTvShow && (watchedEpisodeCount > 0 || isWatching)
	}
	/// Progress from 0...1 based on watched episodes vs total episodes reported by TMDb.
	var watchProgress: Double {
		guard isTvShow else { return 0 }
		let watched = watchedEpisodeCount
		guard watched > 0 else { return 0 }
		let total = Int(numberOfEpisodes)
		guard total > 0 else { return 0 }
		return min(1, Double(watched) / Double(total))
	}
	var watchProgressLabel: String? {
		guard watchProgress > 0 else { return nil }
		let percent = Int((watchProgress * 100).rounded())
		return String(format: NSLocalizedString("%d%% watched", comment: "TV show watch progress in Up Next"), percent)
	}
	var itemReleaseDate: Date {
		itemDate ?? Date.distantPast
	}
	var itemUpcomingReleaseDate: Date {
		if upcomingSeason {
			if let date {
				return date
			}
		}
		return itemDate ?? Date.distantPast
	}
	var itemId: Int {
		Int(id)
	}
	var itemImage: URL? {
		guard let largeCardImage else { return image }
		return largeCardImage
	}
	var itemMedia: MediaType {
		switch contentType {
		case 0: return .movie
		case 1: return .tvShow
		case 2: return .person
		default: return .movie
		}
	}
	var itemSchedule: ItemSchedule {
		if isMovie && date != nil { if itemReleaseDate <= Date() { return .released } }
		switch schedule {
		case 0: return .soon
		case 1: return .released
		case 2: return .production
		case 3: return .cancelled
		case 5: return .renewed
		case 6: return .ended
		default: return .unknown
		}
	}
	var itemLink: URL {
		return URL(string: "https://www.themoviedb.org/\(itemMedia.rawValue)/\(itemId)")!
	}
	var itemDateForNextSeason: String {
		guard let date else { return String() }
#if os(watchOS)
		return date.toShortString()
#else
		return DatesManager.dateString.string(from: date)
#endif
	}
	var itemGlanceInfo: String? {
		switch itemMedia {
		case .tvShow:
			if upcomingSeason {
				if itemDateForNextSeason.isEmpty {
					return "Season \(nextSeasonNumber)"
				}
#if os(watchOS)
				return itemDateForNextSeason
#else
				let season = NSLocalizedString("Season", comment: "")
				return "\(season) \(nextSeasonNumber) • \(itemDateForNextSeason)"
#endif
			}
		default:
#if os(watchOS)
			return itemReleaseDate.toShortString()
#else
			guard let date else { return nil }
			let formmated = DatesManager.dateString.string(from: date)
			return formmated
#endif
		}
		return nil
	}
	var itemReleaseDateQuickInfo: String {
		if isTvShow && firstAirDate != nil { return itemReleaseDate.convertDateToString() }
		if isMovie && date != nil { return itemReleaseDate.convertDateToString() }
		return ""
	}
	var isWatched: Bool {
		return watched
	}
	var isFavorite: Bool {
		return favorite
	}
	var isMovie: Bool {
		if itemMedia == .movie { return true }
		return false
	}
	var isTvShow: Bool {
		if itemMedia == .tvShow { return true }
		return false
	}
	var isReleased: Bool {
		if isArchive { return false }
		if itemMedia == .movie {
			return isReleasedMovie
		} else {
			return isReleasedTvShow
		}
	}
	var isUpcoming: Bool {
		if isArchive { return false }
		if itemMedia == .movie {
			return isUpcomingMovie
		} else {
			return isUpcomingTvShow
		}
	}
	var isReleasedMovie: Bool {
		if itemMedia == .movie {
			if date != nil && itemReleaseDate < Date() && !isWatched { return true }
			if itemSchedule == .released && !notify && !isWatched {
				return true
			}
		}
		return false
	}
	private var isReleasedTvShow: Bool {
		if itemMedia == .tvShow {
			if isWatched { return false }
			if itemSchedule == .ended { return true }
			if itemSchedule == .released && !isWatched { return true }
			if itemSchedule == .cancelled && !isWatched { return true }
			if let firstAirDate {
				if firstAirDate < Date() && !isWatched { return true }
			}
			if itemSchedule == .renewed && nextSeasonNumber == 1 && nextEpisodeNumber > 1 { return true }
			if itemSchedule == .renewed && nextSeasonNumber != 1 { return true }
		}
		return false
	}
	private var isUpcomingMovie: Bool {
		if itemMedia == .movie {
			if itemSchedule == .soon && notify { return true }
			if itemSchedule == .soon { return true }
		}
		return false
	}
	private var isUpcomingTvShow: Bool {
		if itemMedia == .tvShow {
            if let firstAirDate, let date {
                if firstAirDate <= Date() && date <= Date() { return false }
            }
            if itemSchedule == .soon && upcomingSeason && notify { return true }
			if itemSchedule == .soon && upcomingSeason { return true }
			if itemSchedule == .soon && nextSeasonNumber == 1 { return true }
			if itemSchedule == .renewed && notify && date != nil && upcomingSeason { return true }
			if itemSchedule == .renewed && nextSeasonNumber == 1 && nextEpisodeNumber == 1 { return true }
		}
		return false
	}
	var isInProduction: Bool {
		if isArchive { return false }
		if nextSeasonNumber == 1 && itemSchedule == .soon && !isWatched && !notify { return true }
		if itemSchedule == .soon && date == nil  { return true }
		if itemSchedule == .production && nextSeasonNumber == 1 { return true }
		if itemSchedule == .production { return true }
		return false
	}
	var isCurrentlyWatching: Bool {
		if isMovie { return false }
		if isTvShow && isWatched { return false }
		if isArchive || isWatched { return false }
		if isTvShow && isArchive { return false }
		if isTvShow && !(watchedEpisodes?.isEmpty ?? false) { return true }
		return isWatching
	}
	var itemContentID: String {
		return "\(itemId)@\(itemMedia.toInt)"
	}
	var itemDate: Date? {
		if let firstAirDate {
			return firstAirDate
		}
		if let movieReleaseDate {
			return movieReleaseDate
		}
		guard let date else { return nil }
		return date
	}
	var itemSortDate: Date {
		itemDate ?? Date.distantPast
	}
	var canShowOnUpcoming: Bool {
		if isArchive { return false }
		if itemMedia == .tvShow {
			if image != nil && isUpcomingTvShow { return true }
			return false
		} else {
			if image != nil && isUpcomingMovie { return true }
			return false
		}
	}
	var itemHasNote: Bool {
		if userNotes.isEmpty { return false }
		return true
	}
	static var example: WatchlistItem {
		let controller = PersistenceController(inMemory: true)
		let viewContext = controller.container.viewContext
		let item = WatchlistItem(context: viewContext)
		item.title = ItemContent.example.itemTitle
		item.id = Int64(ItemContent.example.id)
		item.image = ItemContent.example.cardImageMedium
		item.contentType = 0
		item.notify = false
		return item
	}
	
	var itemLists: Set<CustomList> {
		return list as? Set<CustomList> ?? []
	}
	var listsArray: [CustomList] {
		let set = list as? Set<CustomList> ?? []
		return set.sorted {
			$0.itemTitle < $1.itemTitle
		}
	}
	var hasItemBeenAddedToList: Bool {
		if itemLists.isEmpty { return false }
		return true
	}
	var itemNextUpNextSeason: Int64 {
		if seasonNumberUpNext == 0 { return 1 }
		return seasonNumberUpNext
	}
	var itemNextUpNextEpisode: Int64 {
		if nextEpisodeNumberUpNext == 0 {
			return 1
		} else {
			return nextEpisodeNumberUpNext
		}
	}
	var backCompatibleSmallCardImage: URL? {
		if backdropPath != nil { return itemCardImageSmall }
		return image
	}
	var backCompatibleCardImage: URL? {
		if backdropPath != nil {
#if os(watchOS)
			return itemCardImageMedium
#else
			return itemCardImageLarge
#endif
		}
		return image
	}
	var backCompatiblePosterImage: URL? {
		if posterPath != nil { return itemPosterImageMedium }
		return mediumPosterImage
	}
	var itemPosterImageMedium: URL? {
        return NetworkService.urlBuilder(size: .medium, path: posterPath)
	}
	var itemPosterImageLarge: URL? {
		return NetworkService.urlBuilder(size: .w780, path: posterPath)
	}
	var itemCardImageSmall: URL? {
		return NetworkService.urlBuilder(size: .small, path: backdropPath)
	}
	var itemCardImageMedium: URL? {
#if os(tvOS) || os(macOS)
		return NetworkService.urlBuilder(size: .w780, path: backdropPath)
#else
		return NetworkService.urlBuilder(size: .w500, path: backdropPath)
#endif
	}
	var itemCardImageLarge: URL? {
		return NetworkService.urlBuilder(size: .large, path: backdropPath)
	}
	var itemCardImageOriginal: URL? {
		return NetworkService.urlBuilder(size: .original, path: backdropPath)
	}
}

