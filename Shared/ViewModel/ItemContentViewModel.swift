//
//  ItemContentViewModel.swift
//  Cronica
//
//  Created by Alexandre Madeira on 02/03/22.
//  

import Foundation
import SwiftUI

@MainActor
class ItemContentViewModel: ObservableObject {
    private let service = NetworkService.shared
    private let notification = NotificationManager.shared
    private let persistence = PersistenceController.shared
    @Published private(set) var content: ItemContent?
    @Published private(set) var recommendations = [ItemContent]()
    @Published private(set) var trailers = [VideoItem]()
    @Published private(set) var credits = [Person]()
    @Published private(set) var errorMessage = "Something went wrong, try again later."
    @Published var showErrorAlert = false
    @Published var isInWatchlist = false
    @Published private(set) var isWatched = false
    @Published private(set) var isFavorite = false
    @Published private(set) var isArchive = false
    @Published private(set) var isPin = false
    @Published private(set) var isLoading = true
    @Published private(set) var showMarkAsButton = false
    @Published private(set) var isItemAddedToAnyList = false
    @Published private(set) var showPoster = false
    private var isNotificationAvailable = false
    private var hasNotificationScheduled = false
    
    func load(id: ItemContent.ID, type: MediaType) async {
        if Task.isCancelled { return }
        if content == nil {
            withAnimation { isLoading = true }
            do {
                content = try await self.service.fetchItem(id: id, type: type)
                guard let content else { return }
                isInWatchlist = persistence.isItemSaved(id: content.itemContentID)
                if content.backdropPath == nil && content.posterPath != nil { showPoster = true }
                let settings = SettingsStore.shared
                if settings.usePostersAsCover {
                    showPoster = true
                }
                withAnimation {
                    if isInWatchlist {
                        isWatched = persistence.isMarkedAsWatched(id: content.itemContentID)
                        isFavorite = persistence.isMarkedAsFavorite(id: content.itemContentID)
                        isArchive = persistence.isItemArchived(id: content.itemContentID)
                        isPin = persistence.isItemPinned(id: content.itemContentID)
                        isItemAddedToAnyList = persistence.isItemAddedToAnyList(content.itemContentID)
                    }
                    isNotificationAvailable = content.itemCanNotify
                    if content.itemStatus == .released {
                        showMarkAsButton = true
                    }
                }
                if recommendations.isEmpty {
                    let contentRecommendations = content.recommendations?.results ?? []
                    if !contentRecommendations.isEmpty {
                        let filteredRecommendations = contentRecommendations.filter { $0.backdropPath != nil && $0.posterPath != nil}
                        recommendations.append(contentsOf: filteredRecommendations.sorted { $0.itemPopularity > $1.itemPopularity })
                    }
                }
                if trailers.isEmpty {
                    trailers.append(contentsOf: content.itemTrailers.prefix(2))
                }
                if credits.isEmpty {
                    let cast = content.credits?.cast ?? []
                    let crew = content.credits?.crew ?? []
                    let combined = cast + crew
                    credits.append(contentsOf: combined)
                }
                isLoading = false
				Task {
					hasNotificationScheduled = await isNotificationScheduled()
				}
#if os(iOS) || os(macOS)
                if isInWatchlist {
                    persistence.update(item: content)
                }
#endif
            } catch {
                if Task.isCancelled { return }
                withAnimation { isLoading = false }
                showErrorAlert = true
                content = nil
                let message = "ID: \(id), type: \(type.title), error: \(error.localizedDescription)"
                CronicaTelemetry.shared.handleMessage(message, for: "ItemContentViewModel.load()")
            }
        }
    }
    
    func checkListStatus() {
        guard let contentID = content?.itemContentID else { return }
        withAnimation {
            isItemAddedToAnyList = persistence.isItemAddedToAnyList(contentID)
        }
    }
      
    /// Automatically saves or delete an item from Watchlist and it's respective notification, if applicable.
    ///
    /// If an item already exists in Watchlist, it'll remove it from there and delete the scheduled notification.
    /// If an item don't exist yet in Watchlist, it'll add to it and schedule a notification, if needed.
    /// - Parameter item: The item to update the Watchlist with.
    func updateWatchlist(with item: ItemContent) {
        if isInWatchlist {
            // Removes item from Watchlist
            withAnimation { isInWatchlist.toggle() }
            let watchlistItem = persistence.fetch(for: item.itemContentID)
            guard let watchlistItem else { return }
            notification.removeNotification(identifier: item.itemContentID)
            persistence.delete(watchlistItem)
        } else {
            // Adds the item to Watchlist
            withAnimation { isInWatchlist.toggle() }
            persistence.save(item)
            if item.itemCanNotify && item.itemFallbackDate.isLessThanTwoWeeksAway() {
                notification.schedule(item)
            }
            CalendarManager.shared.schedule(item)
            if item.itemContentMedia == .tvShow {
                Task {
                    let firstSeason = try? await service.fetchSeason(id: item.id, season: 1)
                    guard let firstEpisode = firstSeason?.episodes?.first,
                          let content = persistence.fetch(for: item.itemContentID)
                    else { return }
                    persistence.updateUpNext(content, episode: firstEpisode)
                }
            }
        }
    }
    
    func checkIfAdded() {
        guard let content else { return }
        if !isInWatchlist {
            let isSaved = persistence.isItemSaved(id: content.itemContentID) 
            if isSaved {
                withAnimation {
                    isInWatchlist = true
                }
                isPin = persistence.isItemPinned(id: content.itemContentID)
                isFavorite = persistence.isMarkedAsFavorite(id: content.itemContentID)
                isWatched = persistence.isMarkedAsWatched(id: content.itemContentID)
                isArchive = persistence.isItemArchived(id: content.itemContentID)
            }
        } else {
            let isSaved = persistence.isItemSaved(id: content.itemContentID)
            if !isSaved {
                withAnimation {
                    isInWatchlist = false
                }
                isPin = false
                isFavorite = false
                isWatched = false
                isArchive = false
            }
        }
    }
    
    func registerNotification() {
		if isInWatchlist && !isArchive {
			guard let content else { return }
            let type = content.itemContentMedia
			// TV Shows
			if type == .tvShow && !hasNotificationScheduled {
				notification.schedule(content)
			}
			// Movies
			if type == .movie {
				if content.itemCanNotify {
					notification.schedule(content)
				}
			}
            CalendarManager.shared.schedule(content)
		}
    }
    
    /// Finds if a given item has notification scheduled.
    private func isNotificationScheduled() async -> Bool {
		guard let contentID = content?.itemContentID else { return false }
		let hasNotificationScheduled = await notification.hasPendingNotification(for: contentID)
		return hasNotificationScheduled
    }
    
    func update(_ property: UpdateItemProperties) {
        guard let content else { return }
        if !isInWatchlist { updateWatchlist(with: content) }
        guard let item = persistence.fetch(for: content.itemContentID) else { return }
        switch property {
        case .watched:
            persistence.updateWatched(for: item)
            withAnimation { isWatched.toggle() }
            Task { await updateSeasons() }
        case .favorite:
            persistence.updateFavorite(for: item)
            withAnimation { isFavorite.toggle() }
        case .pin:
            persistence.updatePin(for: item)
            withAnimation { isPin.toggle() }
        case .archive:
            persistence.updateArchive(for: item)
            withAnimation { isArchive.toggle() }
        }
    }
    
    private func updateSeasons() async {
        guard let content else { return }
        let type = content.itemContentMedia
        if type != .tvShow { return }
        guard let item = persistence.fetch(for: content.itemContentID) else { return }
        if !isWatched {
            /// if item is removed from watched, then all watched episodes will also be removed.
            persistence.removeWatchedEpisodes(for: item)
        } else {
            /// if item is marked as watched, all episodes will also be marked as watched.
            guard let seasons = content.seasons else { return }
            var episodes = [Episode]()
            for season in seasons {
                let result = try? await service.fetchSeason(id: content.id, season: season.seasonNumber)
                if let items = result?.episodes {
                    episodes.append(contentsOf: items)
                }
            }
            if !episodes.isEmpty {
                persistence.updateEpisodeList(to: item, show: item.itemId, episodes: episodes)
            }
        }
    }
}

enum UpdateItemProperties: String, Identifiable, CaseIterable {
    var id: String { rawValue }
    case watched, favorite, pin, archive
    
    var title: String {
        switch self {
        case .watched: String(localized: "Watched")
        case .favorite: String(localized: "Favorite")
        case .pin: String(localized: "Pin")
        case .archive: String(localized: "Archive")
        }
    }
}
