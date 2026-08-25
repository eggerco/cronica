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
    @State private var showUnwatchConfirmation = false
    @State private var showNotReleasedAlert = false
    var body: some View {
        Button(isWatched ? "Unwatched" : "Watched",
               systemImage: isWatched ? "rectangle.badge.checkmark.fill" : "rectangle.badge.checkmark") {
            requestUpdateWatched()
        }
        .confirmationDialog("Reset Episode Progress?",
                            isPresented: $showUnwatchConfirmation,
                            titleVisibility: .visible) {
            Button("Reset Progress", role: .destructive) {
                applyWatchedUpdate(resetEpisodeProgress: true)
            }
            Button("Keep Progress") {
                applyWatchedUpdate(resetEpisodeProgress: false)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Marking this series as unwatched can clear watched episodes. Choose whether to reset progress or keep it.")
        }
        .alert("Not Released Yet", isPresented: $showNotReleasedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You can mark this as watched after it has been released.")
        }
    }
}

extension WatchedButton {
    private func requestUpdateWatched() {
        guard let item = persistence.fetch(for: id) else { return }
        if !item.isWatched && !item.isReleasedForWatching {
            showNotReleasedAlert = true
            return
        }
        if item.isTvShow && item.isWatched && item.hasStartedWatching {
            showUnwatchConfirmation = true
            return
        }
        applyWatchedUpdate(resetEpisodeProgress: true)
    }

    private func applyWatchedUpdate(resetEpisodeProgress: Bool) {
        guard let item = persistence.fetch(for: id) else { return }
        persistence.updateWatched(for: item)
        withAnimation {
            isWatched.toggle()
            popupType = isWatched ? .markedWatched : .removedWatched
            showPopup = true
        }
        guard item.itemMedia == .tvShow else { return }
        Task {
            await updateSeasons(resetEpisodeProgress: resetEpisodeProgress)
        }
    }

    private func updateSeasons(resetEpisodeProgress: Bool) async {
        guard let item = persistence.fetch(for: id) else { return }
        if !item.isWatched {
            if resetEpisodeProgress {
                persistence.removeWatchedEpisodes(for: item)
            }
            return
        }
        let network = NetworkService.shared
        guard let content = try? await network.fetchItem(id: item.itemId, type: .tvShow) else { return }
        guard let seasons = content.itemSeasons else { return }
        var episodes = [Episode]()
        for season in seasons {
            let result = try? await network.fetchSeason(id: item.itemId, season: season)
            if let seasonEpisodes = result?.episodes {
                episodes.append(contentsOf: seasonEpisodes)
            }
        }
        if !episodes.isEmpty {
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
