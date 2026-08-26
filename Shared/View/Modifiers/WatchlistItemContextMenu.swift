//
//  WatchlistItemContextMenu.swift
//  Shared
//
//  Created by Alexandre Madeira on 27/10/22.
//

import SwiftUI

struct WatchlistItemContextMenu: ViewModifier {
    let item: WatchlistItem
    @Binding var isWatched: Bool
    @Binding var isFavorite: Bool
    @Binding var isPin: Bool
    @Binding var isArchive: Bool
    @Binding var showNote: Bool
    @Binding var showCustomListView: Bool
    @Binding var popupType: ActionPopupItems?
    @Binding var showPopup: Bool
    private let context = PersistenceController.shared
    private let notification = NotificationManager.shared
    @State private var settings = SettingsStore.shared
    @State private var showDeleteConfirmation = false
    @State private var isNotificationsMuted = false
    @State private var isHiddenFromUpNext = false
    @State private var isHiddenFromWatchlist = false
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \CustomList.isPin, ascending: false),
                                    NSSortDescriptor(keyPath: \CustomList.title, ascending: true)],
                  animation: .default) private var lists: FetchedResults<CustomList>
    func body(content: Content) -> some View {
#if os(watchOS)
        content
#elseif os(tvOS)
        content
            .contextMenu {
                watchedButton
                favoriteButton
                pinButton
                customListButton
                archiveButton
                HideFromWatchlistButton(id: item.itemContentID, isHidden: $isHiddenFromWatchlist)
                Divider()
                deleteButton
            }
            .confirmationDialog("Are You Sure?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Confirm", role: .destructive, action: remove)
            } message: {
                Text("Remove \(item.itemTitle) from your Watchlist?")
            }
            .onAppear { refreshMuteAndHideState() }
#elseif os(visionOS)
        content
            .swipeActions(edge: .leading, allowsFullSwipe: settings.allowFullSwipe) {
                primaryLeftSwipeActions
                secondaryLeftSwipeActions
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: settings.allowFullSwipe) {
                primaryRightSwipeActions
                secondaryRightSwipeActions
            }
            .contextMenu {
                share
                watchedButton
                favoriteButton
                pinButton
                archiveButton
                customListButton
                reviewButton
                HideFromWatchlistButton(id: item.itemContentID, isHidden: $isHiddenFromWatchlist)
                if item.isTvShow {
                    HideFromUpNextButton(id: item.itemContentID, isHidden: $isHiddenFromUpNext)
                }
                MuteNotificationsButton(id: item.itemContentID, isMuted: $isNotificationsMuted)
                Divider()
                deleteButton
            }
            .confirmationDialog("Are You Sure?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Confirm", role: .destructive, action: remove)
            } message: {
                Text("Remove \(item.itemTitle) from your Watchlist?")
            }
            .onAppear { refreshMuteAndHideState() }
#else
        content
            .swipeActions(edge: .leading, allowsFullSwipe: settings.allowFullSwipe) {
                primaryLeftSwipeActions
                secondaryLeftSwipeActions
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: settings.allowFullSwipe) {
                primaryRightSwipeActions
                secondaryRightSwipeActions
                hideSwipeAction
            }
            .contextMenu {
                share
                watchedButton
                favoriteButton
                pinButton
                archiveButton
                customListButton
                reviewButton
#if os(iOS)
                TrackOnLockScreenButton(contentID: item.itemContentID)
#endif
                HideFromWatchlistButton(id: item.itemContentID, isHidden: $isHiddenFromWatchlist)
                if item.isTvShow {
                    HideFromUpNextButton(id: item.itemContentID, isHidden: $isHiddenFromUpNext)
                }
                MuteNotificationsButton(id: item.itemContentID, isMuted: $isNotificationsMuted)
                Divider()
                deleteButton
            } preview: {
                ContextMenuPreviewImage(title: item.itemTitle,
                                        image: item.backCompatibleCardImage,
                                        overview: String())
            }
            .confirmationDialog("Are You Sure?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Confirm", role: .destructive, action: remove)
            } message: {
                Text("Remove \(item.itemTitle) from your Watchlist?")
            }
            .onAppear { refreshMuteAndHideState() }
#endif
    }

    private func refreshMuteAndHideState() {
        isNotificationsMuted = !item.shouldNotify
        isHiddenFromUpNext = item.hideFromUpNext
        isHiddenFromWatchlist = item.hideFromWatchlist
    }
    
    private var watchedButton: some View {
        WatchedButton(id: item.itemContentID,
                      isWatched: $isWatched,
                      popupType: $popupType,
                      showPopup: $showPopup)
    }
    
    private var favoriteButton: some View {
        FavoriteButton(id: item.itemContentID,
                       isFavorite: $isFavorite,
                       popupType: $popupType,
                       showPopup: $showPopup)
    }
    
    private var pinButton: some View {
        PinButton(id: item.itemContentID,
                  isPin: $isPin,
                  popupType: $popupType,
                  showPopup: $showPopup)
    }
    
    private var archiveButton: some View {
        ArchiveButton(id: item.itemContentID,
                      isArchive: $isArchive,
                      popupType: $popupType,
                      showPopup: $showPopup)
    }

    private var hideSwipeAction: some View {
        HideFromWatchlistButton(id: item.itemContentID, isHidden: $isHiddenFromWatchlist)
            .tint(.gray)
    }
    
#if !os(watchOS)
    private var customListButton: some View {
        Menu {
            ForEach(lists) { list in
                Button {
                    PersistenceController.shared.updateList(for: item.itemContentID, to: list)
                } label: {
                    HStack {
                        if list.itemsSet.contains(item) {
#if os(macOS)
                            Image(systemName: "checkmark")
#else
                            Image(systemName: "checkmark.circle.fill")
#endif
                        }
                        Text(list.itemTitle)
                    }
                }
            }
        } label: {
            Label("Add To List", systemImage: "rectangle.on.rectangle.angled")
        }
    }
#endif
    
    private var reviewButton: some View {
        Button("Review", systemImage: "note.text") {
            showNote.toggle()
        }
    }
    
    @ViewBuilder
    private var share: some View {
#if os(iOS) || os(macOS)
        switch settings.shareLinkPreference {
        case .tmdb: ShareLink(item: item.itemLink)
        case .cronica:
            if let cronicaUrl {
                ShareLink(item: cronicaUrl, subject: Text(item.itemTitle), message: Text(item.itemTitle))
            } else {
                ShareLink(item: item.itemLink)
            }
        }
        
#else
        EmptyView()
#endif
    }
    
    private var cronicaUrl: URL? {
        AppWebsite.detailsURL(
            contentID: item.itemContentID,
            posterPath: item.posterPath,
            title: item.itemTitle
        )
    }
    
    @ViewBuilder
    private var primaryLeftSwipeActions: some View {
        switch settings.primaryLeftSwipe {
        case .markWatch: watchedButton.tint(item.isWatched ? .yellow : .green)
        case .markFavorite: favoriteButton.tint(item.isFavorite ? .orange : .purple)
        case .markPin: pinButton.tint(item.isPin ? .gray : .teal)
        case .markArchive: archiveButton.tint(item.isArchive ? .gray : .indigo)
        case .delete: deleteButton
        case .share: share
        }
    }
    
    @ViewBuilder
    private var secondaryLeftSwipeActions: some View {
        switch settings.secondaryLeftSwipe {
        case .markWatch: watchedButton.tint(item.isWatched ? .yellow : .green)
        case .markFavorite: favoriteButton.tint(item.isFavorite ? .orange : .purple)
        case .markPin: pinButton.tint(item.isPin ? .gray : .teal)
        case .markArchive: archiveButton.tint(item.isArchive ? .gray : .indigo)
        case .delete: deleteButton
        case .share: share
        }
    }
    
    @ViewBuilder
    private var primaryRightSwipeActions: some View {
        switch  settings.primaryRightSwipe {
        case .markWatch: watchedButton.tint(item.isWatched ? .yellow : .green)
        case .markFavorite: favoriteButton.tint(item.isFavorite ? .orange : .purple)
        case .markPin: pinButton.tint(item.isPin ? .gray : .teal)
        case .markArchive: archiveButton.tint(item.isArchive ? .gray : .indigo)
        case .delete: deleteButton
        case .share: share
        }
    }
    
    @ViewBuilder
    private var secondaryRightSwipeActions: some View {
        switch settings.secondaryRightSwipe {
        case .markWatch: watchedButton.tint(item.isWatched ? .yellow : .green)
        case .markFavorite: favoriteButton.tint(item.isFavorite ? .orange : .purple)
        case .markPin: pinButton.tint(item.isPin ? .gray : .teal)
        case .markArchive: archiveButton.tint(item.isArchive ? .gray : .indigo)
        case .delete: deleteButton
        case .share: share
        }
    }
    
    private var deleteButton: some View {
        Button(role: .destructive) {
            if settings.showRemoveConfirmation {
                showDeleteConfirmation = true
            } else {
                remove()
            }
        } label: {
            Label("Remove", systemImage: "minus.circle.fill")
#if os(macOS)
                .labelStyle(.titleOnly)
                .foregroundColor(.red)
#endif
        }
        .tint(.red)
    }
    
    private func remove() {
        notification.removeNotification(identifier: item.itemContentID)
        withAnimation { context.delete(item) }
    }
}
