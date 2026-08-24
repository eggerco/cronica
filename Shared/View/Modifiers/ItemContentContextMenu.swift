//
//  ItemContentContextMenu.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 06/06/22.
//

import SwiftUI

struct ItemContentContextMenu: ViewModifier {
	let item: ItemContent
	@Binding var showPopup: Bool
	@Binding var isInWatchlist: Bool
	@Binding var isWatched: Bool
	@Binding var isFavorite: Bool
	@Binding var isPin: Bool
	@Binding var isArchive: Bool
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
                Divider()
				switch settings.shareLinkPreference {
				case .cronica: if let cronicaUrl { ShareLink(item: cronicaUrl) }
				case .tmdb: ShareLink(item: item.itemURL)
				}
#endif
				if isInWatchlist {
					watchedButton
					favoriteButton
					pinButton
					archiveButton
#if !os(tvOS)
                    CustomListButton(id: item.itemContentID, showCustomListView: $showCustomListView)
					Button {
						showNote.toggle()
					} label: {
						Label("Review", systemImage: "note.text")
					}
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
                Button("Confirm", action: remove)
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
                                    popupType: $popupType, showRemoveConfirmation: $showRemoveConfirmation)
					.tint(isInWatchlist ? .red : .green)
				} else {
					primaryLeftSwipeActions
					secondaryLeftSwipeActions
				}
			}
			.swipeActions(edge: .trailing, allowsFullSwipe: settings.allowFullSwipe) {
				if isInWatchlist {
					primaryRightSwipeActions
					secondaryRightSwipeActions
				}
			}
#endif
#endif
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
				context.save(self.item)
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
					withAnimation {
						isInWatchlist.toggle()
						isWatched.toggle()
					}
				}
				return
			}
			context.save(item)
			let content = context.fetch(for: item.itemContentID)
			guard let content else { return }
			context.updateWatched(for: content)
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
				withAnimation {
					isInWatchlist.toggle()
					isWatched.toggle()
				}
			}
		}
	}
    
    private func remove() {
        let persistence = PersistenceController.shared
        let notification = NotificationManager.shared
        let watchlistItem = persistence.fetch(for: item.itemContentID)
        if let watchlistItem {
            if watchlistItem.notify {
                notification.removeNotification(identifier: item.itemContentID)
            }
            persistence.delete(watchlistItem)
            withAnimation {
                showPopup.toggle()
                isInWatchlist.toggle()
                popupType = isInWatchlist ? .addedWatchlist : .removedWatchlist
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
		case .cronica: if let cronicaUrl { ShareLink(item: cronicaUrl) }
		case .tmdb: ShareLink(item: item.itemURL)
		}
#else
		EmptyView()
#endif
	}
	
	@ViewBuilder
	private var primaryLeftSwipeActions: some View {
		switch settings.primaryLeftSwipe {
		case .markWatch: watchedButton.tint(isWatched ? .yellow : .green)
		case .markFavorite: favoriteButton.tint(isFavorite ? .orange : .purple)
		case .markPin: pinButton.tint(isPin ? .gray : .teal)
		case .markArchive: archiveButton.tint(isArchive ? .gray : .indigo)
		case .delete: watchlistButton.tint(isInWatchlist ? .red :  .blue)
		case .share: shareButton
		}
	}
	
	@ViewBuilder
	private var secondaryLeftSwipeActions: some View {
		switch settings.secondaryLeftSwipe {
		case .markWatch: watchedButton.tint(isWatched ? .yellow : .green)
		case .markFavorite: favoriteButton.tint(isFavorite ? .orange : .purple)
		case .markPin: pinButton.tint(isPin ? .gray : .teal)
		case .markArchive: archiveButton.tint(isArchive ? .gray : .indigo)
		case .delete: watchlistButton.tint(isInWatchlist ? .red :  .blue)
		case .share: shareButton
		}
	}
	
	@ViewBuilder
	private var primaryRightSwipeActions: some View {
		switch  settings.primaryRightSwipe {
		case .markWatch: watchedButton.tint(isWatched ? .yellow : .green)
		case .markFavorite: favoriteButton.tint(isFavorite ? .orange : .purple)
		case .markPin: pinButton.tint(isPin ? .gray : .teal)
		case .markArchive: archiveButton.tint(isArchive ? .gray : .indigo)
		case .delete: watchlistButton.tint(isInWatchlist ? .red :  .blue)
		case .share: shareButton
		}
	}
	
	@ViewBuilder
	private var secondaryRightSwipeActions: some View {
		switch settings.secondaryRightSwipe {
		case .markWatch: watchedButton.tint(isWatched ? .yellow : .green)
		case .markFavorite: favoriteButton.tint(isFavorite ? .orange : .purple)
		case .markPin: pinButton.tint(isPin ? .gray : .teal)
		case .markArchive: archiveButton.tint(isArchive ? .gray : .indigo)
		case .delete: watchlistButton.tint(isInWatchlist ? .red :  .blue)
		case .share: shareButton
		}
	}
}
