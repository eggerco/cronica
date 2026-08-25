//
//  PersistenceController-WatchlistItem.swift
//  Cronica
//
//  Created by Alexandre Madeira on 14/02/23.
//

import Foundation
import CoreData

extension PersistenceController {
    // MARK: Basic CRUD
    /// Creates a new WatchlistItem and saves it.
    /// - Parameter content: The content that is used to populate the new WatchlistItem.
    func save(_ content: ItemContent) {
        if !self.isItemSaved(id: content.itemContentID) {
            let item = WatchlistItem(context: container.viewContext)
            item.contentType = content.itemContentMedia.toInt
            item.title = content.itemTitle
            item.originalTitle = content.originalTitle
            item.id = Int64(content.id)
            item.tmdbID = Int64(content.id)
            item.contentID = content.itemContentID
            item.imdbID = content.imdbId
			item.posterPath = content.posterPath
			item.backdropPath = content.backdropPath
            item.schedule = content.itemStatus.toInt
            item.notify = content.itemCanNotify
            item.lastValuesUpdated = Date()
			if content.itemContentMedia == .movie {
				item.date = content.itemFallbackDate
			} else {
				if let nextEpisode = content.nextEpisodeToAir,
                   let date = nextEpisode.airDate?.toDate() {
                    if item.date != date {
                        item.date = date
                    }
                }
                if let episode = content.lastEpisodeToAir?.episodeNumber {
                    item.nextEpisodeNumber = Int64(episode)
                }
                if let firstAirDate = content.firstAirDate {
                    if let date = DatesManager.dateFormatter.date(from: firstAirDate) {
                        item.firstAirDate = date
                    }
                }
                item.upcomingSeason = content.hasUpcomingSeason
                item.nextSeasonNumber = Int64(content.nextEpisodeToAir?.seasonNumber ?? 0)
                if let total = content.numberOfEpisodes, total > 0 {
                    item.numberOfEpisodes = Int64(total)
                }
			}
            item.formattedDate = content.itemTheatricalString
            save()
#if !os(watchOS)
            if let saved = fetch(for: content.itemContentID) {
                let tmdb = saved.itemId
                let media = saved.itemMedia
                let imdb = saved.imdbID
                Task { @MainActor in
                    SimklPushService.shared.enqueueAdd(tmdb: tmdb, media: media, status: .plantowatch, imdb: imdb)
                }
            }
#endif
        }
    }
    
    func fetch(for id: String) -> WatchlistItem? {
        let request: NSFetchRequest<WatchlistItem> = WatchlistItem.fetchRequest()
        let idPredicate = NSPredicate(format: "contentID == %@", id)
        request.predicate = idPredicate
        let items = try? container.viewContext.fetch(request)
        guard let items else { return nil }
		if items.isEmpty { return nil }
		guard let firstItem = items.first else { return nil }
		return firstItem
    }
    
    /// Updates a WatchlistItem on Core Data.
    func update(item content: ItemContent) {
        if isItemSaved(id: content.itemContentID) {
            let item = fetch(for: content.itemContentID)
            guard let item else { return }
            if item.title != content.itemTitle {
                item.title = content.itemTitle
            }
            if item.originalTitle != content.originalTitle {
                item.originalTitle = content.originalTitle
            }
			if item.posterPath != content.posterPath {
				item.posterPath = content.posterPath
			}
			if item.backdropPath != content.backdropPath {
				item.backdropPath = content.backdropPath
			}
            if item.schedule != content.itemStatus.toInt {
                item.schedule = content.itemStatus.toInt
            }
            if item.notify != content.itemCanNotify {
                item.notify = content.itemCanNotify
            }
            if item.formattedDate != content.itemTheatricalString {
                item.formattedDate = content.itemTheatricalString
            }
            if content.itemContentMedia == .tvShow {
				if let nextEpisode = content.nextEpisodeToAir,
                   let date = nextEpisode.airDate?.toDate(),
                   item.date != date {
                    item.date = date
                }
                if let episode = content.lastEpisodeToAir {
                    let episodeNumber = Int64(episode.itemEpisodeNumber)
                    if item.lastEpisodeNumber != episodeNumber {
                        item.lastEpisodeNumber = episodeNumber
                    }
                }
                if let episode = content.nextEpisodeToAir {
                    if item.nextEpisodeNumber != Int64(episode.itemEpisodeNumber) {
                        item.nextEpisodeNumber = Int64(episode.itemEpisodeNumber)
                    }
                }
                if item.upcomingSeason != content.hasUpcomingSeason {
                    item.upcomingSeason = content.hasUpcomingSeason
                }
                if let nextSeasonNumber = content.nextEpisodeToAir?.itemSeasonNumber {
                    let season = Int64(nextSeasonNumber)
                    if item.nextSeasonNumber != season {
                        item.nextSeasonNumber = season
                    }
                }
                if let total = content.numberOfEpisodes, total > 0, item.numberOfEpisodes != Int64(total) {
                    item.numberOfEpisodes = Int64(total)
                }
				if let firstAirDate = content.firstAirDate {
					if !firstAirDate.isEmpty {
						if let date = DatesManager.dateFormatter.date(from: firstAirDate) {
							if item.firstAirDate != date {
								item.firstAirDate = date
							}
						}
					}
				}
            } else {
				if let releaseDate = content.itemTheatricalDate {
					if item.movieReleaseDate != releaseDate {
						item.movieReleaseDate = releaseDate
					}
				}
				if let date = content.itemFallbackDate {
					if item.date != date {
						item.date = date
					}
				}
            }
            if item.hasChanges && item.isReleasedMovie {
                item.lastValuesUpdated = Date()
            }
            save()
        }
    }
    
    /// Deletes a WatchlistItem from Core Data.
    func delete(_ content: WatchlistItem) {
        let viewContext = container.viewContext
        let item = try? viewContext.existingObject(with: content.objectID)
        guard let item else { return }
#if !os(watchOS)
        let tmdb = content.itemId
        let media = content.itemMedia
        let imdb = content.imdbID
        Task { @MainActor in
            SimklPushService.shared.enqueueRemove(tmdb: tmdb, media: media, imdb: imdb)
        }
#endif
        let notification = NotificationManager.shared
        notification.removeNotification(identifier: content.itemContentID)
        CalendarManager.shared.removeEvent(identifier: content.itemContentID)
        viewContext.delete(item)
        save()
    }
    
    // MARK: Properties updates
    func updateWatched(for item: WatchlistItem) {
        item.watched.toggle()
        if item.isTvShow {
            item.isWatching.toggle()
        }
        if item.isWatched && SettingsStore.shared.removeFromPinOnWatched {
            item.isPin = false
        }
        save()
#if !os(watchOS)
        let tmdb = item.itemId
        let media = item.itemMedia
        let imdb = item.imdbID
        let watched = item.isWatched
        let watching = item.isWatching
        Task { @MainActor in
            if watched {
                SimklPushService.shared.enqueueWatched(tmdb: tmdb, media: media, imdb: imdb)
            } else if watching {
                SimklPushService.shared.enqueueAdd(tmdb: tmdb, media: media, status: .watching, imdb: imdb)
            }
        }
#endif
    }
    
    func updateFavorite(for item: WatchlistItem) {
        item.favorite.toggle()
        save()
    }
    
    func updatePin(for item: WatchlistItem) {
        item.isPin.toggle()
        save()
    }
    
    func updateArchive(for item: WatchlistItem) {
        item.isArchive.toggle()
        if item.isArchive {
            NotificationManager.shared.removeNotification(identifier: item.itemContentID)
            CalendarManager.shared.removeEvent(identifier: item.itemContentID)
        }
        item.shouldNotify.toggle()
        if item.isTvShow {
            item.isWatching.toggle()
            item.displayOnUpNext.toggle()
        }
        save()
#if !os(watchOS)
        if item.isArchive {
            let tmdb = item.itemId
            let media = item.itemMedia
            let imdb = item.imdbID
            Task { @MainActor in
                SimklPushService.shared.enqueueArchive(tmdb: tmdb, media: media, imdb: imdb)
            }
        }
#endif
        if !item.isArchive {
            Task {
                let newValues = try? await NetworkService.shared.fetchItem(id: item.itemId,
                                                                     type: item.itemMedia)
                guard let newValues else { return }
                self.update(item: newValues)
                CalendarManager.shared.schedule(newValues)
            }
        }
    }
    
    func updateReview(for item: WatchlistItem, rating: Int, notes: String) {
        item.userNotes = notes
        item.userRating = Int64(rating)
        save()
    }
    
    // MARK: Properties read
    func isItemSaved(id: String) -> Bool {
        let viewContext = container.viewContext
        let request: NSFetchRequest<WatchlistItem> = WatchlistItem.fetchRequest()
        request.predicate = NSPredicate(format: "contentID == %@", id)
        let numberOfObjects = try? viewContext.count(for: request)
        guard let numberOfObjects else { return false }
        if numberOfObjects > 0 {
            return true
        }
        return false
    }
    
    /// Returns a boolean indicating the status of 'watched' on a given item.
    func isMarkedAsWatched(id: String) -> Bool {
        let item = fetch(for: id)
        guard let item else { return false }
        return item.watched
    }
    
    /// Returns a boolean indicating the status of 'favorite' on a given item.
    func isMarkedAsFavorite(id: String) -> Bool {
        let item = fetch(for: id)
        guard let item else { return false }
        return item.favorite
    }
    
    func isItemPinned(id: String) -> Bool {
        let item = fetch(for: id)
        guard let item else { return false }
        return item.isPin
    }
    
    func isItemArchived(id: String) -> Bool {
        let item = fetch(for: id)
        guard let item else { return false }
        return item.isArchive
    }
    
    // MARK: Episode
    func updateEpisodeList(to item: WatchlistItem, show: Int, episodes: [Episode]) {
        var watched = ""
        for episode in episodes {
			if !watched.contains("-\(episode.id)@\(episode.itemSeasonNumber)") {
				watched.append("-\(episode.id)@\(episode.itemSeasonNumber)")
			}
        }
        item.watchedEpisodes?.append(watched)
        item.isWatching = true
        if let lastWatched = episodes.last {
            item.lastSelectedSeason = Int64(lastWatched.itemSeasonNumber)
            item.lastWatchedEpisode = Int64(lastWatched.id)
        }
        item.lastValuesUpdated = Date()
        save()
    }
      
    func updateEpisodeList(show: Int, season: Int, episode: Int, nextEpisode: Episode? = nil) {
        let contentId = "\(show)@\(MediaType.tvShow.toInt)"
        if isItemSaved(id: contentId) {
            let item = fetch(for: contentId)
            guard let item else { return }
            if isEpisodeSaved(show: show, season: season, episode: episode) {
                let watched = item.watchedEpisodes?.replacingOccurrences(of: "-\(episode)@\(season)", with: "")
                item.watchedEpisodes = watched
                item.isWatching = true
            } else {
                let watched = "-\(episode)@\(season)"
                item.watchedEpisodes?.append(watched)
                item.isWatching = true
                
                if let nextEpisode {
                    updateUpNext(item, episode: nextEpisode)
                }
                item.lastSelectedSeason = Int64(season)
                item.lastWatchedEpisode = Int64(episode)
                item.displayOnUpNext = true
                item.lastValuesUpdated = Date()
            }
            save()
        }
    }
    
    func updateWatchedEpisodes(for item: WatchlistItem, with episode: Episode) {
        let wasWatched = isEpisodeSaved(show: item.itemId, season: episode.itemSeasonNumber, episode: episode.id)
        if wasWatched {
            let watched = item.watchedEpisodes?.replacingOccurrences(of: "-\(episode.id)@\(episode.itemSeasonNumber)",
                                                                     with: "")
            item.watchedEpisodes = watched
        } else {
            let watched = "-\(episode.id)@\(episode.itemSeasonNumber)"
            item.watchedEpisodes?.append(watched)
            item.lastSelectedSeason = Int64(episode.itemSeasonNumber)
            item.lastWatchedEpisode = Int64(episode.id)
        }
        item.lastValuesUpdated = Date()
        item.isWatching = true
        save()
#if !os(watchOS)
        if !wasWatched, let season = episode.seasonNumber, let number = episode.episodeNumber {
            let showID = item.itemId
            let imdb = item.imdbID
            Task { @MainActor in
                SimklPushService.shared.enqueueEpisode(showID: showID, season: season, episode: number, imdb: imdb)
            }
        }
#endif
    }
    
    func removeFromUpNext(_ item: WatchlistItem) {
        item.displayOnUpNext = false
        save()
    }
    
    func updateUpNext(_ item: WatchlistItem, episode: Episode) {
		guard let seasonNumber = episode.seasonNumber, let episodeNumber = episode.episodeNumber else { return }
        item.nextEpisodeNumberUpNext = Int64(episodeNumber)
        item.seasonNumberUpNext = Int64(seasonNumber)
        item.displayOnUpNext = true
        save()
    }
    
    func removeWatchedEpisodes(for item: WatchlistItem) {
        item.watchedEpisodes = String()
        item.displayOnUpNext = false
        item.isWatching = false
        save()
    }
    
    func getLastSelectedSeason(_ id: String) -> Int? {
        let item = fetch(for: id)
        guard let item else { return nil }
        if item.lastSelectedSeason == 0 { return 1 }
        return Int(item.lastSelectedSeason)
    }
    
    func fetchLastWatchedEpisode(for id: Int) -> Int? {
        let contentId = "\(id)@\(MediaType.tvShow.toInt)"
        let item = fetch(for: contentId)
        guard let item else { return nil }
        if !item.isWatching { return nil }
        if item.lastWatchedEpisode == 0 { return nil }
        return Int(item.lastWatchedEpisode)
    }
    
    func isEpisodeSaved(show: Int, season: Int, episode: Int) -> Bool {
        let contentId = "\(show)@\(MediaType.tvShow.toInt)"
        if isItemSaved(id: contentId) {
            let item = fetch(for: contentId)
            guard let item, let watched = item.watchedEpisodes else { return false }
            if watched.contains("-\(episode)@\(season)") { return true }
        }
        return false
    }
    
    func isItemAddedToAnyList(_ id: String) -> Bool {
        let item = fetch(for: id)
        guard let hasItemAddedToAnyList = item?.hasItemBeenAddedToList else { return false }
        return hasItemAddedToAnyList
    }

    func updateEpisodeCount(for item: WatchlistItem, total: Int) {
        guard total > 0, item.numberOfEpisodes != Int64(total) else { return }
        item.numberOfEpisodes = Int64(total)
        save()
    }
}
