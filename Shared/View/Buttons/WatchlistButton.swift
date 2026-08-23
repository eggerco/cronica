//
//  WatchlistButton.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 04/05/23.
//

import SwiftUI

struct WatchlistButton: View {
    let id: String
    @Binding var isInWatchlist: Bool
    @Binding var showPopup: Bool
    @Binding var showListSelector: Bool
    @Binding var popupType: ActionPopupItems?
    private let persistence = PersistenceController.shared
    private let notification = NotificationManager.shared
    @Binding var showRemoveConfirmation: Bool
    var body: some View {
        Button(role: isInWatchlist ? .destructive : nil) {
            if !isInWatchlist { HapticManager.shared.successHaptic() }
            if isInWatchlist, SettingsStore.shared.showRemoveConfirmation {
                showRemoveConfirmation = true
            } else {
                updateWatchlist()
            }
        } label: {
            Label(isInWatchlist ? "Remove": "Add",
                  systemImage: isInWatchlist ? "minus.circle" : "plus.circle")
#if os(macOS)
            .foregroundColor(isInWatchlist ? .red : nil)
            .labelStyle(.titleOnly)
#endif
        }
    }
    
    private func updateWatchlist() {
        if isInWatchlist {
            remove()
        } else {
            add()
        }
    }
    
    private func remove() {
        let watchlistItem = persistence.fetch(for: id)
        if let watchlistItem {
            if watchlistItem.notify {
                notification.removeNotification(identifier: id)
            }
            persistence.delete(watchlistItem)
            displayConfirmation()
        }
    }
    
    private func add() {
        Task {
            let identifier = id
            let type = identifier.last ?? "0"
            var media: MediaType = .movie
            if type == "1" {
                media = .tvShow
            }
            let contentID = identifier.dropLast(2)
            guard let itemId = Int(contentID) else { return }
            let content = try? await NetworkService.shared.fetchItem(id: itemId, type: media)
            guard let content else { return }
            persistence.save(content)
            registerNotification(content)
            displayConfirmation()
            if content.itemContentMedia == .tvShow { addFirstEpisodeToUpNext(content) }
            if SettingsStore.shared.openListSelectorOnAdding {
                showListSelector.toggle()
            }
            popupType = .addedWatchlist
        }
    }
    
    private func registerNotification(_ item: ItemContent) {
        if item.itemCanNotify && item.itemFallbackDate.isLessThanTwoWeeksAway() {
            notification.schedule(item)
        }
    }
    
    private func displayConfirmation() {
        withAnimation {
            showPopup.toggle()
            isInWatchlist.toggle()
            popupType = isInWatchlist ? .addedWatchlist : .removedWatchlist
        }
    }
    
    private func addFirstEpisodeToUpNext(_ item: ItemContent) {
        Task {
            let firstSeason = try? await NetworkService.shared.fetchSeason(id: item.id, season: 1)
            guard let firstEpisode = firstSeason?.episodes?.first,
                  let content = persistence.fetch(for: item.itemContentID)
            else { return }
            persistence.updateUpNext(content, episode: firstEpisode)
        }
    }
}

#Preview {
    WatchlistButton(id: ItemContent.example.itemContentID,
                    isInWatchlist: .constant(true),
                    showPopup: .constant(false),
                    showListSelector: .constant(false),
                    popupType: .constant(.addedWatchlist), showRemoveConfirmation: .constant(false))
}
