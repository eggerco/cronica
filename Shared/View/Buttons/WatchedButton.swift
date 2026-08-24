//
//  WatchedButton.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 04/05/23.
//

import SwiftUI

struct WatchedButton: View {
    let id: String
    @Binding var isWatched: Bool
    @Binding var popupType: ActionPopupItems?
    @Binding var showPopup: Bool
    private let persistence = PersistenceController.shared
    var body: some View {
        Button(isWatched ? "Unwatched" : "Watched",
               systemImage: isWatched ? "rectangle.badge.checkmark.fill" : "rectangle.badge.checkmark",
               action: updateWatched)
    }
}

extension WatchedButton {
    private func updateWatched() {
        guard let item = persistence.fetch(for: id) else { return }
        persistence.updateWatched(for: item)
        withAnimation {
            isWatched.toggle()
            popupType = isWatched ? .markedWatched : .removedWatched
            showPopup = true
        }
        if item.itemMedia == .tvShow { updateSeasons() }
    }
    
    private func updateSeasons() {
        Task {
            let network = NetworkService.shared
            guard let item = persistence.fetch(for: id) else { return }
            guard let content = try? await network.fetchItem(id: item.itemId, type: .tvShow) else { return }
            guard let seasons = content.itemSeasons else { return }
            var episodes = [Episode]()
            for season in seasons {
                let result = try? await network.fetchSeason(id: item.itemId, season: season)
                if let seasonEpisodes = result?.episodes {
                    for seasonEpisode in seasonEpisodes {
                        episodes.append(seasonEpisode)
                    }
                }
            }
            persistence.updateEpisodeList(to: item, show: item.itemId, episodes: episodes)
        }
    }
}

#Preview {
    WatchedButton(id: ItemContent.example.itemContentID,
                  isWatched: .constant(true),
                  popupType: .constant(.markedWatched),
                  showPopup: .constant(false))
}
