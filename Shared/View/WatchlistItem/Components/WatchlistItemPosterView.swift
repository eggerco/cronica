//
//  WatchlistItemPosterView.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 20/12/22.
//

import SwiftUI
import NukeUI

struct WatchlistItemPosterView: View {
    let content: WatchlistItem
    @State private var isInWatchlist = true
    @State private var isWatched = false
    @State private var isFavorite = false
    @State private var isPin = false
    @State private var isArchive = false
    @StateObject private var settings = SettingsStore.shared
    @State private var showNote = false
    @State private var showCustomListView = false
    @Binding var showPopup: Bool
    @Binding var popupType: ActionPopupItems?
    var body: some View {
        NavigationLink(value: content) {
            if settings.isCompactUI {
                compact
            } else {
                image
            }
        }
#if os(tvOS)
        .buttonStyle(.card)
        .watchlistContextMenu(item: content,
                              isWatched: $isWatched,
                              isFavorite: $isFavorite,
                              isPin: $isPin,
                              isArchive: $isArchive,
                              showNote: $showNote,
                              showCustomList: $showCustomListView,
                              popupType: $popupType,
                              showPopup: $showPopup)
#else
        .buttonStyle(.plain)
#endif
        .accessibilityLabel(Text(content.itemTitle))
        .sheet(isPresented: $showNote) {
            ReviewView(id: content.itemContentID, showView: $showNote)
        }
        .sheet(isPresented: $showCustomListView) {
            ItemContentCustomListSelector(contentID: content.itemContentID,
                                          showView: $showCustomListView,
                                          title: content.itemTitle,
                                          image: content.itemPosterImageMedium)
        }
    }
    
    private var image: some View {
        WatchlistPosterImageView(item: content)
            .overlay {
                if isInWatchlist {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            if isFavorite {
                                Image(systemName: "suit.heart.fill")
                                    .imageScale(.small)
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding([.vertical])
                                    .padding(.horizontal)
#if os(tvOS)
                                    .font(.caption)
#endif
                            }
                            if !isFavorite, isWatched {
                                Image(systemName: "rectangle.badge.checkmark.fill")
                                    .imageScale(.small)
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding([.vertical])
                                    .padding(.horizontal)
#if os(tvOS)
                                    .font(.caption)
#endif
                            }
                            if !isFavorite, !isWatched {
                                Image(systemName: "square.stack.fill")
                                    .imageScale(.small)
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding([.vertical, .trailing])
#if os(tvOS)
                                    .font(.caption)
#endif
                            }
                            
                        }
                        .background {
                            if content.mediumPosterImage != nil {
                                Color.black.opacity(0.6)
                                    .mask {
                                        LinearGradient(colors:
                                                        [Color.black,
                                                         Color.black.opacity(0.924),
                                                         Color.black.opacity(0.707),
                                                         Color.black.opacity(0.383),
                                                         Color.black.opacity(0)],
                                                       startPoint: .bottom,
                                                       endPoint: .top)
                                    }
                            }
                            
                        }
                    }
                }
            }
            .frame(width: settings.isCompactUI ? DrawingConstants.compactPosterWidth : DrawingConstants.posterWidth,
                   height: settings.isCompactUI ? DrawingConstants.compactPosterHeight : DrawingConstants.posterHeight)
            .clipShape(RoundedRectangle(cornerRadius: settings.isCompactUI ? CronicaDesign.Radius.compact : CronicaDesign.Radius.media,
                                        style: .continuous))
            .shadow(
                color: .black.opacity(CronicaDesign.Shadow.mediaOpacity),
                radius: CronicaDesign.Shadow.mediaRadius,
                x: 0,
                y: CronicaDesign.Shadow.mediaY
            )
            .padding(.zero)
            .applyHoverEffect()
#if !os(tvOS)
            .watchlistContextMenu(item: content,
                                  isWatched: $isWatched,
                                  isFavorite: $isFavorite,
                                  isPin: $isPin,
                                  isArchive: $isArchive,
                                  showNote: $showNote,
                                  showCustomList: $showCustomListView,
                                  popupType: $popupType,
                                  showPopup: $showPopup)
#endif
            .task {
                isWatched = content.isWatched
                isFavorite = content.isFavorite
                isPin = content.isPin
                isArchive = content.isArchive
            }
    }
    
    private var compact: some View {
        VStack {
            image
            HStack {
                Text(content.itemTitle)
                    .lineLimit(2)
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .accessibilityHidden(true)
                Spacer()
            }
            Spacer()
        }
        .frame(maxWidth: DrawingConstants.compactPosterWidth)
    }
}

#Preview {
    WatchlistItemPosterView(content: .example, showPopup: .constant(false), popupType: .constant(nil))
}

private struct WatchlistPosterImageView: View {
    let item: WatchlistItem
    var body: some View {
        LazyImage(url: item.backCompatiblePosterImage) { state in
            if let image = state.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .transition(.opacity)
            } else {
                PosterPlaceholder(title: item.itemTitle, type: item.itemMedia)
            }
        }
    }
}

private struct DrawingConstants {
#if !os(tvOS)
    static let posterWidth: CGFloat = 160
    static let posterHeight: CGFloat = 240
#else
    static let posterWidth: CGFloat = 260
    static let posterHeight: CGFloat = 380
#endif
    static let compactPosterWidth: CGFloat = 80
    static let compactPosterHeight: CGFloat = 140
}
