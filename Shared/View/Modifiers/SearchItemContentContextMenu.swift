//
//  SearchItemContentContextMenu.swift
//  Story
//
//  Created by Alexandre Madeira on 29/10/23.
//

import SwiftUI

struct SearchItemContentContextMenu: ViewModifier {
    let item: SearchItemContent
    @Binding var showPopup: Bool
    @Binding var isInWatchlist: Bool
    @Binding var isWatched: Bool
    private let context = PersistenceController.shared
    @Binding var showNote: Bool
    @Binding var showCustomListView: Bool
    @Binding var popupType: ActionPopupItems?
    @StateObject private var settings = SettingsStore.shared
    @State private var showRemoveConfirmation = false
    func body(content: Content) -> some View {
#if !os(watchOS)
        return content
            .contextMenu {
#if os(iOS) || os(macOS)
                switch settings.shareLinkPreference {
                case .cronica: if let cronicaUrl {
                    ShareLink(item: cronicaUrl, subject: Text(item.itemTitle), message: Text(item.itemTitle))
                }
                case .tmdb: ShareLink(item: item.itemURL)
                }
#endif
                if isInWatchlist {
                    watchedButton
#if !os(tvOS)
                    CustomListButton(id: item.itemContentID, showCustomListView: $showCustomListView)
                    Button {
                        showNote.toggle()
                    } label: {
                        Label("Review", systemImage: "note.text")
                    }
#if os(iOS)
                    TrackOnLockScreenButton(contentID: item.itemContentID)
#endif
#endif
                }
                Divider()
                if !isInWatchlist {
                    addAndMarkWatchedButton
                }
                watchlistButton
            } preview: {
                ContextMenuPreviewImage(title: item.itemTitle,
                                        image: item.cardImageLarge,
                                        overview: item.itemOverview)
            }
            .confirmationDialog("Are You Sure?", isPresented: $showRemoveConfirmation, titleVisibility: .visible) {
                Button("Confirm", role: .destructive, action: removeFromWatchlist)
            } message: {
                Text("Remove \(item.itemTitle) from your Watchlist?")
            }
#if !os(tvOS)
            .swipeActions(edge: .leading, allowsFullSwipe: settings.allowFullSwipe) {
                if !isInWatchlist {
                    WatchlistButton(id: item.itemContentID,
                                    isInWatchlist: $isInWatchlist,
                                    showPopup: $showPopup,
                                    showListSelector: $showCustomListView,
                                    popupType: $popupType,
                                    showRemoveConfirmation: $showRemoveConfirmation)
                    .tint(.green)
                } else {
                    WatchedButton(id: item.itemContentID,
                                  isWatched: $isWatched,
                                  popupType: $popupType,
                                  showPopup: $showPopup)
                    .tint(isWatched ? .yellow : .blue)
                }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: settings.allowFullSwipe) {
                if isInWatchlist {
                    WatchlistButton(id: item.itemContentID,
                                    isInWatchlist: $isInWatchlist,
                                    showPopup: $showPopup,
                                    showListSelector: $showCustomListView,
                                    popupType: $popupType,
                                    showRemoveConfirmation: $showRemoveConfirmation)
                    .tint(.red)
                } else {
                    Button {
                        addAndMarkAsWatched()
                    } label: {
                        Label("Add & Mark Watched", systemImage: "rectangle.badge.checkmark.fill")
                    }
                    .tint(.blue)
                }
            }
#endif
#endif
    }

    private func removeFromWatchlist() {
        let persistence = PersistenceController.shared
        let notification = NotificationManager.shared
        if let watchlistItem = persistence.fetch(for: item.itemContentID) {
            if watchlistItem.notify {
                notification.removeNotification(identifier: item.itemContentID)
            }
            persistence.delete(watchlistItem)
        }
        withAnimation {
            isInWatchlist = false
            popupType = .removedWatchlist
            showPopup = true
        }
    }
    
    private var addAndMarkWatchedButton: some View {
        Button(action: addAndMarkAsWatched) {
            Label("Add & Mark Watched", systemImage: "rectangle.badge.checkmark.fill")
        }
    }
    
    private func addAndMarkAsWatched() {
        Task {
            let item = try? await NetworkService.shared.fetchItem(id: self.item.id, type: self.item.itemContentMedia)
            guard let item else {
                return
            }
            context.save(item)
            let content = context.fetch(for: item.itemContentID)
            guard let content else { return }
            if !content.isWatched && !content.isReleasedForWatching {
                await MainActor.run {
                    withAnimation { isInWatchlist = true }
                }
                return
            }
            context.updateWatched(for: content)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    isInWatchlist.toggle()
                    isWatched.toggle()
                }
            }
        }
    }
    
    private var cronicaUrl: URL? {
        AppWebsite.detailsURL(
            contentID: item.itemContentID,
            posterPath: item.posterPath,
            title: item.itemTitle
        )
    }
    
    private var watchedButton: some View {
        WatchedButton(id: item.itemContentID,
                      isWatched: $isWatched,
                      popupType: $popupType,
                      showPopup: $showPopup)
    }
    
    private var watchlistButton: some View {
        WatchlistButton(id: item.itemContentID,
                        isInWatchlist: $isInWatchlist,
                        showPopup: $showPopup,
                        showListSelector: $showCustomListView,
                        popupType: $popupType,
                        showRemoveConfirmation: $showRemoveConfirmation)
    }
    
    @ViewBuilder
    private var shareButton: some View {
#if !os(tvOS)
        switch settings.shareLinkPreference {
        case .cronica: if let cronicaUrl {
            ShareLink(item: cronicaUrl, subject: Text(item.itemTitle), message: Text(item.itemTitle))
        }
        case .tmdb: ShareLink(item: item.itemURL)
        }
#else
        EmptyView()
#endif
    }
}
