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
            switch await WatchlistAddService.add(contentID: id, persistence: persistence) {
            case .added(let content):
                registerNotification(content)
                displayConfirmation()
                if SettingsStore.shared.openListSelectorOnAdding {
                    showListSelector.toggle()
                }
                popupType = .addedWatchlist
            case .alreadyOnWatchlist, .unsupportedURL, .notFound, .fetchFailed:
                break
            }
        }
    }
    
    private func registerNotification(_ item: ItemContent) {
        if item.itemCanNotify && item.itemFallbackDate.isLessThanTwoWeeksAway() {
            notification.schedule(item)
        }
        CalendarManager.shared.schedule(item)
    }
    
    private func displayConfirmation() {
        withAnimation {
            showPopup = true
            isInWatchlist.toggle()
            popupType = isInWatchlist ? .addedWatchlist : .removedWatchlist
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
