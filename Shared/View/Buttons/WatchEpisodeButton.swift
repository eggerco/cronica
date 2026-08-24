//
//  WatchEpisodeButton.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 15/08/22.
//

import SwiftUI

struct WatchEpisodeButton: View {
    let episode: Episode
    let season: Int
    let show: Int
    @Binding var isWatched: Bool
    private let persistence = PersistenceController.shared
    private let network = NetworkService.shared
    @State private var isItemSaved = false
    var body: some View {
        Button(action: update) {
#if !os(macOS)
            VStack {
                Image(systemName: isWatched ? "rectangle.fill.badge.checkmark" : "rectangle.badge.checkmark")
                    .symbolEffect(isWatched ? .bounce.down : .bounce.up,
                                  value: isWatched)
                Text("Watched")
                    .lineLimit(1)
                    .padding(.top, 2)
                    .font(.caption)
            }
#if !os(tvOS)
            .frame(width: 80, height: 40)
#elseif !os(watchOS)
            .padding(.vertical, 4)
#endif
#else
            Label(isWatched ? "Unwatched" : "Watched",
                  systemImage: isWatched ? "rectangle.fill.badge.checkmark" : "rectangle.badge.checkmark")
            .symbolEffect(isWatched ? .bounce.down : .bounce.up,
                          value: isWatched)
#endif
        }
#if os(iOS)
        .applyHoverEffect()
#elseif os(watchOS)
        .padding(.horizontal)
#endif
    }
}

extension WatchEpisodeButton {
    private func update() {
        checkIfItemIsSaved()
        if !isItemSaved {
            Task {
                await fetch()
                await handleList()
            }
        } else {
            Task {
                await handleList()
            }
        }
    }
    
    private func checkIfItemIsSaved() {
        let contentId = "\(show)@\(MediaType.tvShow.toInt)"
        let isShowSaved = persistence.isItemSaved(id: contentId)
        isItemSaved = isShowSaved
    }
    
    private func handleList() async {
        let contentId = "\(show)@\(MediaType.tvShow.toInt)"
        let item = persistence.fetch(for: contentId)
        guard let item else { return }
        persistence.updateWatchedEpisodes(for: item, with: episode)
        await MainActor.run {
            withAnimation { self.isWatched.toggle() }
        }
        let nextEpisode = await EpisodeHelper().fetchNextEpisode(for: self.episode, show: show)
        guard let nextEpisode else { return }
        persistence.updateUpNext(item, episode: nextEpisode)
    }
    
    private func fetch() async {
        let content = try? await network.fetchItem(id: show, type: .tvShow)
        guard let content else { return }
        persistence.save(content)
        if content.itemCanNotify && content.itemFallbackDate.isLessThanTwoWeeksAway() {
            NotificationManager.shared.schedule(content)
        }
        CalendarManager.shared.schedule(content)
        isItemSaved = true
    }
}
