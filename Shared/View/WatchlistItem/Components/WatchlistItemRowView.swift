//
//  WatchlistItemRowView.swift
//  Cronica
//
//  Created by Alexandre Madeira on 07/02/22.
//

import SwiftUI
import NukeUI

struct WatchlistItemRowView: View {
    let content: WatchlistItem
    @State private var isWatched: Bool = false
    @State private var isFavorite: Bool = false
    @State private var isPin = false
    @State private var isArchive = false
    @StateObject private var settings = SettingsStore.shared
    @State private var showNote = false
    @State private var showCustomListView = false
    @Binding var showPopup: Bool
    @Binding var popupType: ActionPopupItems?
    var body: some View {
        NavigationLink(value: content) {
            HStack {
                ZStack {
                    LazyImage(url: content.backCompatibleSmallCardImage) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            ZStack {
                                Rectangle().fill(.gray.gradient)
                                Image(systemName: "popcorn.fill")
                                    .font(.title3)
                                    .fontWidth(.expanded)
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding()
                            }
                            .frame(width: DrawingConstants.imageWidth,
                                   height: DrawingConstants.imageHeight)
                        }
                    }
                    .transition(.opacity)
                    .frame(width: DrawingConstants.imageWidth,
                           height: DrawingConstants.imageHeight)
                    if isWatched || content.watched {
                        Color.black.opacity(0.5)
                        Image(systemName: "rectangle.fill.badge.checkmark").foregroundColor(.white)
                    }
                }
                .frame(width: DrawingConstants.imageWidth,
                       height: DrawingConstants.imageHeight)
                .clipShape(RoundedRectangle(cornerRadius: DrawingConstants.imageRadius))
                .shadow(color: .black.opacity(0.2), radius: 2.5, x: 0, y: 2.5)
                .overlay(alignment: .bottomTrailing) {
                    if content.isTvShow, content.watchProgress > 0, !(content.isWatched) {
                        WatchProgressRing(progress: content.watchProgress, size: 20)
                            .padding(4)
                            .background(.ultraThinMaterial, in: Circle())
                            .padding(4)
                    }
                }
                .applyHoverEffect()
                VStack(alignment: .leading) {
                    HStack {
                        Text(content.itemTitle)
                            .lineLimit(DrawingConstants.textLimit)
                            .font(.callout)
                            .fontDesign(.rounded)
                            .fontWeight(.medium)
                        if content.itemHasRating {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.yellow)
                                Text("\(content.userRating)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .accessibilityLabel(String(localized: "Rated \(content.userRating) of 5"))
                        }
                    }
                    HStack {
#if os(watchOS)
                        Text("\(content.itemMedia.title)")
                            .fontDesign(.rounded)
                            .font(.caption)
                            .foregroundColor(.secondary)
#else
                        if let watchedLabel = content.itemWatchedDateLabel {
                            Text("\(content.itemMedia.title) • \(String(localized: "Watched")) \(watchedLabel)")
                                .lineLimit(1)
                                .fontDesign(.rounded)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else if content.itemReleaseDateQuickInfo.isEmpty {
                            Text("\(content.itemMedia.title)")
                                .fontDesign(.rounded)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            if settings.showDateOnWatchlist {
                                Text("\(content.itemMedia.title) • \(content.itemReleaseDateQuickInfo)")
                                    .lineLimit(1)
                                    .fontDesign(.rounded)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("\(content.itemMedia.title)")
                                    .fontDesign(.rounded)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
#endif
                        Spacer()
                    }
                }
                .padding(.leading, 2)
#if !os(watchOS)
                Spacer()
                IconGridView(isFavorite: $isFavorite, isPin: $isPin)
                    .accessibilityHidden(true)
#endif
            }
            .task {
                isWatched = content.isWatched
                isFavorite = content.isFavorite
                isPin = content.isPin
                isArchive = content.isArchive
            }
#if os(iOS) || os(macOS)
            .sheet(isPresented: $showNote) {
                ReviewView(id: content.itemContentID, showView: $showNote)
            }
#endif
            .accessibilityElement(children: .combine)
#if !os(watchOS)
            .watchlistContextMenu(item: content,
                                  isWatched: $isWatched,
                                  isFavorite: $isFavorite,
                                  isPin: $isPin,
                                  isArchive: $isArchive,
                                  showNote: $showNote,
                                  showCustomList: $showCustomListView,
                                  popupType: $popupType,
                                  showPopup: $showPopup)
            .sheet(isPresented: $showCustomListView) {
                ItemContentCustomListSelector(contentID: content.itemContentID,
                                              showView: $showCustomListView,
                                              title: content.itemTitle,
                                              image: content.itemPosterImageMedium)
            }
#endif
        }
    }
}

#Preview {
    WatchlistItemRowView(content: .example, showPopup: .constant(false), popupType: .constant(nil))
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
