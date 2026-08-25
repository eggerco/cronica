//
//  ItemContentItemView.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 04/05/23.
//

import SwiftUI
import NukeUI

struct ItemContentRowView: View {
	let item: ItemContent
	@State private var isWatched = false
	@State private var isFavorite = false
	@State private var isPin = false
	@State private var isArchive = false
	@Binding var showPopup: Bool
	@State private var isInWatchlist = false
	@State private var canReview = true
	@State private var showNote = false
	@State private var showCustomListView = false
	@Binding var popupType: ActionPopupItems?
	private let persistence = PersistenceController.shared
	var showNotificationDate = false
	var body: some View {
		NavigationLink(value: item) {
			HStack {
				ZStack {
                    LazyImage(url: item.cardImageSmall) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            ZStack {
                                Rectangle().fill(.gray.gradient)
                                Image(systemName: "popcorn.fill")
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .frame(width: DrawingConstants.imageWidth,
                                   height: DrawingConstants.imageHeight)
                        }
                    }
                    .transition(.opacity)
                    .frame(width: DrawingConstants.imageWidth,
                           height: DrawingConstants.imageHeight)
                    .shadow(radius: 2.5)
					if isWatched {
						Color.black.opacity(0.5)
						Image(systemName: "rectangle.fill.badge.checkmark")
							.foregroundColor(.white)
					}
				}
				.frame(width: DrawingConstants.imageWidth,
					   height: DrawingConstants.imageHeight)
				.clipShape(RoundedRectangle(cornerRadius: DrawingConstants.imageRadius))
                .shadow(color: .black.opacity(0.2), radius: 2.5, x: 0, y: 2.5)
				VStack(alignment: .leading, spacing: 6) {
                    Text(item.itemTitle)
                        .lineLimit(DrawingConstants.textLimit)
                        .fontWeight(.medium)
                    Text(showNotificationDate ? item.itemNotificationDescription : item.itemSearchDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
				}
#if os(iOS) || os(macOS)
				Spacer()
				IconGridView(isFavorite: $isFavorite, isPin: $isPin)
					.accessibilityHidden(true)
#endif
			}
			.itemContentContextMenu(item: item,
									isWatched: $isWatched,
									showPopup: $showPopup,
									isInWatchlist: $isInWatchlist,
									showNote: $showNote,
									showCustomList: $showCustomListView,
									popupType: $popupType,
									isFavorite: $isFavorite,
									isPin: $isPin,
									isArchive: $isArchive)
			.task {
				isInWatchlist = persistence.isItemSaved(id: item.itemContentID)
				if isInWatchlist {
					isWatched = persistence.isMarkedAsWatched(id: item.itemContentID)
					isPin = persistence.isItemPinned(id: item.itemContentID)
					isFavorite = persistence.isMarkedAsFavorite(id: item.itemContentID)
					isArchive = persistence.isItemArchived(id: item.itemContentID)
				}
			}
			.sheet(isPresented: $showNote) {
                ReviewView(id: item.itemContentID, showView: $showNote)
			}
			.sheet(isPresented: $showCustomListView) {
                ItemContentCustomListSelector(contentID: item.itemContentID,
                                              showView: $showCustomListView,
                                              title: item.itemTitle,
                                              image: item.posterImageMedium)
			}
		}
	}
}

private struct DrawingConstants {
#if os(watchOS)
    static let imageWidth: CGFloat = 80.5
    static let textLimit: Int = 2
#else
    static let imageWidth: CGFloat = 88
    static let textLimit: Int = 1
#endif
    static let imageHeight: CGFloat = 55
    static let imageRadius: CGFloat = 12
}

#Preview {
    ItemContentRowView(item: .example, showPopup: .constant(false), popupType: .constant(nil))
}
