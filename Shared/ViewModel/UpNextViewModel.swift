//
//  UpNextViewModel.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 17/07/23.
//

import SwiftUI

@MainActor
class UpNextViewModel: ObservableObject {
    static let shared = UpNextViewModel()
    @Published var isLoaded = false
    @Published var episodes = [UpNextEpisode]()
    @Published var isWatched = false
    @Published var scrollToInitial = false
    private let network = NetworkService.shared
    private let persistence = PersistenceController.shared
    private let helper = EpisodeHelper()
    private let settings = SettingsStore.shared
    private init() { }

    func load(_ items: FetchedResults<WatchlistItem>) async {
        guard !isLoaded else { return }
        await performLoad(items)
    }

    func reload(_ items: FetchedResults<WatchlistItem>) async {
        withAnimation { self.isLoaded = false }
        await MainActor.run {
            withAnimation(.easeInOut) {
                self.episodes.removeAll()
            }
        }
        await performLoad(items)
    }

    private func performLoad(_ items: FetchedResults<WatchlistItem>) async {
        let preparedItems = await prepareItems(Array(items))
        var content = [UpNextEpisode]()
        for item in preparedItems {
            if let episode = await fetchUpNextEpisode(for: item), !content.contains(episode) {
                content.append(episode)
            }
        }
        self.episodes = sortEpisodes(content)
        await MainActor.run {
            withAnimation(.easeInOut) {
                self.isLoaded = true
            }
        }
        WidgetSnapshotPublisherBridge.scheduleRefreshIfAvailable()
    }

    func skipEpisode(for item: UpNextEpisode) async {
        let nextEpisode = await helper.fetchNextEpisode(for: item.episode, show: item.showID)
        guard let nextEpisode,
              let show = persistence.fetch(for: "\(item.showID)@\(MediaType.tvShow.toInt)") else {
            return
        }
        persistence.updateUpNext(show, episode: nextEpisode)
        await handleWatched(item)
    }

    func hideFromUpNext(_ content: UpNextEpisode) async {
        guard let show = persistence.fetch(for: "\(content.showID)@\(MediaType.tvShow.toInt)") else {
            return
        }
        persistence.updateHideFromUpNext(for: show, hidden: true)
        await MainActor.run {
            withAnimation(.easeInOut) {
                self.episodes.removeAll(where: { $0.showID == content.showID })
            }
        }
    }

    func handleWatched(_ content: UpNextEpisode?) async {
        guard let content else { return }
        await MainActor.run {
            withAnimation(.smooth) {
                self.episodes.removeAll(where: { $0.episode.id == content.episode.id })
            }
        }

        let nextEpisode = await helper.fetchNextEpisode(for: content.episode, show: content.showID)
        guard let nextEpisode else { return }

        var isReleased = nextEpisode.isItemReleased
        if nextEpisode.airDate == nil {
            let showContent = try? await network.fetchItem(id: content.showID, type: .tvShow)
            if showContent?.itemStatus == .ended { isReleased = true }
        }
        if isReleased,
           let show = persistence.fetch(for: "\(content.showID)@\(MediaType.tvShow.toInt)") {
            let episode = makeEpisode(from: show, episode: nextEpisode, sortedDate: Date())
            await MainActor.run {
                withAnimation(.easeInOut) {
                    self.episodes.append(episode)
                    self.episodes = sortEpisodes(self.episodes)
                    self.scrollToInitial = true
                }
            }
        }
    }

    func checkForNewEpisodes(_ items: FetchedResults<WatchlistItem>) async {
        let preparedItems = await prepareItems(Array(items))
        for item in preparedItems {
            let result = try? await network.fetchEpisode(tvID: item.id,
                                                         season: item.seasonNumberUpNext,
                                                         episodeNumber: item.nextEpisodeNumberUpNext)
            if let result {
                let resultSeasonNumber = result.seasonNumber ?? 0
                let isWatched = persistence.isEpisodeSaved(show: item.itemId,
                                                           season: resultSeasonNumber,
                                                           episode: result.id)
                let isInEpisodeList = episodes.contains(where: { $0.episode.id == result.id })
                let isItemAlreadyLoadedInList = episodes.contains(where: { $0.showID == item.itemId })
                var isReleased = result.isItemReleased
                if result.airDate == nil {
                    let show = try? await network.fetchItem(id: item.itemId, type: .tvShow)
                    if show?.itemStatus == .ended { isReleased = true }
                }
                if isReleased && !isWatched && !isInEpisodeList {
                    if isItemAlreadyLoadedInList {
                        await MainActor.run {
                            withAnimation(.easeInOut) {
                                self.episodes.removeAll(where: { $0.showID == item.itemId })
                            }
                        }
                    }
                    let episode = makeEpisode(from: item, episode: result, sortedDate: item.itemLastUpdateDate)
                    await MainActor.run {
                        withAnimation(.easeInOut) {
                            self.episodes.append(episode)
                            self.episodes = sortEpisodes(self.episodes)
                        }
                    }
                }
            }
        }
    }

    func markAsWatched(_ content: UpNextEpisode) async {
        let contentId = "\(content.showID)@\(MediaType.tvShow.toInt)"
        let item = persistence.fetch(for: contentId)
        guard let item else { return }
        persistence.updateWatchedEpisodes(for: item, with: content.episode)
        await MainActor.run {
            withAnimation(.easeInOut) {
                self.episodes.removeAll(where: { $0.episode.id == content.episode.id })
            }
        }
        let nextEpisode = await EpisodeHelper().fetchNextEpisode(for: content.episode, show: content.showID)
        guard let nextEpisode else { return }
        persistence.updateUpNext(item, episode: nextEpisode)
        var isReleased = nextEpisode.isItemReleased
        if nextEpisode.airDate == nil {
            let showContent = try? await network.fetchItem(id: content.showID, type: .tvShow)
            if showContent?.itemStatus == .ended { isReleased = true }
        }
        if isReleased {
            let episode = makeEpisode(from: item, episode: nextEpisode, sortedDate: Date())
            await MainActor.run {
                withAnimation(.easeInOut) {
                    self.episodes.append(episode)
                    self.episodes = sortEpisodes(self.episodes)
                }
            }
        }
    }

    private func prepareItems(_ items: [WatchlistItem]) async -> [WatchlistItem] {
        var filtered = items.filter { $0.firstAirDate != nil }
        if settings.hideUnstartedUpNext {
            filtered = filtered.filter(\.hasStartedWatching)
        }
        for item in filtered where item.isTvShow && item.numberOfEpisodes == 0 {
            await backfillEpisodeCount(for: item)
        }
        return sortItems(filtered)
    }

    private func sortItems(_ items: [WatchlistItem]) -> [WatchlistItem] {
        switch settings.upNextSortOrder {
        case .recentActivity:
            return items.sorted { $0.itemLastUpdateDate > $1.itemLastUpdateDate }
        case .watchProgress:
            return items.sorted {
                if $0.watchProgress != $1.watchProgress {
                    return $0.watchProgress > $1.watchProgress
                }
                if $0.watchedEpisodeCount != $1.watchedEpisodeCount {
                    return $0.watchedEpisodeCount > $1.watchedEpisodeCount
                }
                return $0.itemLastUpdateDate > $1.itemLastUpdateDate
            }
        }
    }

    private func sortEpisodes(_ episodes: [UpNextEpisode]) -> [UpNextEpisode] {
        switch settings.upNextSortOrder {
        case .recentActivity:
            return episodes.sorted { $0.sortedDate > $1.sortedDate }
        case .watchProgress:
            return episodes.sorted {
                if $0.watchProgress != $1.watchProgress {
                    return $0.watchProgress > $1.watchProgress
                }
                return $0.sortedDate > $1.sortedDate
            }
        }
    }

    private func backfillEpisodeCount(for item: WatchlistItem) async {
        guard let show = try? await network.fetchItem(id: item.itemId, type: .tvShow),
              let total = show.numberOfEpisodes, total > 0 else {
            return
        }
        persistence.updateEpisodeCount(for: item, total: total)
    }

    private func fetchUpNextEpisode(for item: WatchlistItem) async -> UpNextEpisode? {
        let result = try? await network.fetchEpisode(tvID: item.id,
                                                     season: item.itemNextUpNextSeason,
                                                     episodeNumber: item.itemNextUpNextEpisode)
        guard let result else { return nil }
        let seasonNumber = result.seasonNumber ?? 0
        let isWatched = persistence.isEpisodeSaved(show: item.itemId,
                                                     season: seasonNumber,
                                                     episode: result.id)
        var isReleased = result.isItemReleased
        if result.airDate == nil {
            let show = try? await network.fetchItem(id: item.itemId, type: .tvShow)
            if show?.itemStatus == .ended { isReleased = true }
        }
        if isReleased && !isWatched {
            let content = makeEpisode(from: item, episode: result, sortedDate: item.itemLastUpdateDate)
            if !episodes.contains(where: { $0.episode.id == content.episode.id }) {
                return content
            }
        } else if isWatched {
            let nextSeasonNumber = item.seasonNumberUpNext + 1
            let nextEpisode = try? await network.fetchEpisode(tvID: item.id,
                                                              season: nextSeasonNumber,
                                                              episodeNumber: 1)
            guard let nextEpisode else { return nil }
            let isNextEpisodeWatched = persistence.isEpisodeSaved(show: item.itemId,
                                                                  season: Int(nextSeasonNumber),
                                                                  episode: nextEpisode.id)
            let show = try? await network.fetchItem(id: item.itemId, type: .tvShow)
            let isReleased = show?.itemStatus == .ended ? true : nextEpisode.isItemReleased
            if isReleased && !isNextEpisodeWatched {
                let content = makeEpisode(from: item, episode: nextEpisode, sortedDate: item.itemLastUpdateDate)
                if !episodes.contains(where: { $0.episode.id == content.episode.id }) {
                    return content
                }
            }
        }
        return nil
    }

    private func makeEpisode(from item: WatchlistItem, episode: Episode, sortedDate: Date) -> UpNextEpisode {
        UpNextEpisode(id: episode.id,
                      showTitle: item.itemTitle,
                      showID: item.itemId,
                      backupImage: item.backCompatibleCardImage,
                      episode: episode,
                      sortedDate: sortedDate,
                      watchProgress: item.watchProgress)
    }
}
