//
//  PersistenceController-WatchlistItem+ShareExtension.swift
//  Cronica Share Extension
//

import CoreData
import CronicaCore

#if CRONICA_SHARE_EXTENSION
extension PersistenceController {
    func save(_ content: ItemContent) {
        guard !isItemSaved(id: content.itemContentID) else { return }

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
               let date = nextEpisode.airDate?.toDate(),
               item.date != date {
                item.date = date
            }
            if let episode = content.lastEpisodeToAir?.episodeNumber {
                item.nextEpisodeNumber = Int64(episode)
            }
            if let firstAirDate = content.firstAirDate,
               let date = DatesManager.dateFormatter.date(from: firstAirDate) {
                item.firstAirDate = date
            }
            item.upcomingSeason = content.hasUpcomingSeason
            item.nextSeasonNumber = Int64(content.nextEpisodeToAir?.seasonNumber ?? 0)
            if let total = content.numberOfEpisodes, total > 0 {
                item.numberOfEpisodes = Int64(total)
            }
        }

        item.formattedDate = content.itemTheatricalString
        item.runtimeMinutes = content.itemRuntimeMinutes
        save()
    }

    func fetch(for id: String) -> WatchlistItem? {
        let request: NSFetchRequest<WatchlistItem> = WatchlistItem.fetchRequest()
        request.predicate = NSPredicate(format: "contentID == %@", id)
        let items = try? container.viewContext.fetch(request)
        return items?.first
    }

    func isItemSaved(id: String) -> Bool {
        fetch(for: id) != nil
    }

    func updateUpNext(_ item: WatchlistItem, episode: Episode) {
        guard let seasonNumber = episode.seasonNumber,
              let episodeNumber = episode.episodeNumber
        else { return }

        item.nextEpisodeNumberUpNext = Int64(episodeNumber)
        item.seasonNumberUpNext = Int64(seasonNumber)
        if !item.hideFromUpNext {
            item.displayOnUpNext = true
        }
        save()
    }
}
#endif
