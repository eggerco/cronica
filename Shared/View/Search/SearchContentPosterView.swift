//
//  SearchContentPosterView.swift
//  Cronica
//
//  Created by Alexandre Madeira on 11/08/23.
//

import SwiftUI
import NukeUI

struct SearchContentPosterView: View {
    let item: SearchItemContent
    private let context = PersistenceController.shared
    @State private var isInWatchlist = false
    @State private var isWatched = false
    @State private var isPin = false
    @State private var isFavorite = false
    @State private var isArchive = false
    @State private var showNote = false
    @State private var showCustomListView = false
    @Binding var showPopup: Bool
    @Binding var popupType: ActionPopupItems?
    @StateObject private var settings = SettingsStore.shared
    @FocusState var isStackFocused: Bool
#if os(macOS)
    @State private var isOnHover = false
#endif
    var body: some View {
        VStack(alignment: .leading) {
            if settings.isCompactUI {
                compact
            } else {
                image
#if os(tvOS) || os(macOS)
                HStack {
                    Text(item.itemTitle)
                        .padding(.top, 4)
                        .font(.caption)
                        .lineLimit(2)
#if os(tvOS)
                        .foregroundStyle(isStackFocused ? .primary : .secondary)
#else
                        .foregroundStyle(isOnHover ? .primary : .secondary)
#endif
                        .frame(maxWidth: DrawingConstants.posterWidth)
                    Spacer()
                }
                Spacer()
#endif
            }
        }
#if os(tvOS)
        .buttonStyle(.card)
        .focused($isStackFocused)
#else
        .buttonStyle(.plain)
#endif
        .accessibilityAddTraits(.isButton)
        .accessibility(label: Text(item.itemTitle))
#if os(macOS)
        .onHover { onHover in
            isOnHover = onHover
        }
#endif
    }
    
    private var image: some View {
        NavigationLink(value: item) {
            SearchPosterImageView(imageUrl: item.posterImageMedium, title: item.itemTitle, type: item.itemContentMedia)
                .overlay{ overlay }
                .transition(.opacity)
                .frame(width: settings.isCompactUI ? DrawingConstants.compactPosterWidth : DrawingConstants.posterWidth,
                       height: settings.isCompactUI ? DrawingConstants.compactPosterHeight : DrawingConstants.posterHeight)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: settings.isCompactUI ? CronicaDesign.Radius.compact : CronicaDesign.Radius.media,
                        style: .continuous
                    )
                )
                .shadow(radius: DrawingConstants.shadowRadius)
                .padding(.zero)
                .applyHoverEffect()
                .task {
                    withAnimation {
                        isInWatchlist = context.isItemSaved(id: item.itemContentID)
                        if isInWatchlist {
                            isWatched = context.isMarkedAsWatched(id: item.itemContentID)
                            isPin = context.isItemPinned(id: item.itemContentID)
                            isFavorite = context.isMarkedAsFavorite(id: item.itemContentID)
                            isArchive = context.isItemArchived(id: item.itemContentID)
                        }
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
        .searchItemContextMenu(item: item,
                               showPopup: $showPopup,
                               isInWatchlist: $isInWatchlist,
                               isWatched: $isWatched,
                               showNote: $showNote,
                               showCustomList: $showCustomListView,
                               popupType: $popupType)
    }
    
    @ViewBuilder
    private var overlay: some View {
        if isInWatchlist {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    if !settings.isCompactUI {
                        if isArchive {
                            Image(systemName: "archivebox.fill")
                                .imageScale(.small)
                                .foregroundColor(.white.opacity(0.9))
                                .padding([.vertical])
                                .padding(.trailing, 4)
                        }
                        if isPin {
                            Image(systemName: "pin.fill")
                                .imageScale(.small)
                                .foregroundColor(.white.opacity(0.9))
                                .padding([.vertical])
                                .padding(.trailing, 4)
                        }
                    }
                    if isFavorite {
                        Image(systemName: "suit.heart")
                            .imageScale(.small)
                            .foregroundColor(.white.opacity(0.9))
                            .padding([.vertical])
                            .padding(.trailing, 4)
                    }
                    if isWatched {
                        Image(systemName: "rectangle.badge.checkmark")
                            .imageScale(.small)
                            .foregroundColor(.white.opacity(0.9))
                            .padding([.vertical])
                            .padding(.trailing, 4)
                    }
                    Image(systemName: "square.stack")
                        .imageScale(.small)
                        .foregroundColor(.white.opacity(0.9))
                        .padding([.vertical, .trailing])
                }
                .background {
                    if item.posterImageMedium != nil {
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
    
    private var compact: some View {
        VStack(alignment: .leading) {
            image
            HStack {
                Text(item.itemTitle)
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

private struct SearchPosterImageView: View {
    let imageUrl: URL?
    let title: String
    let type: MediaType
    var body: some View {
        LazyImage(url: imageUrl) { state in
            if let image = state.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                PosterPlaceholder(title: title, type: type)
            }
        }
    }
}

private struct DrawingConstants {
#if os(tvOS)
    static let posterWidth: CGFloat = 260
    static let posterHeight: CGFloat = 380
#else
    static let posterWidth: CGFloat = 160
    static let posterHeight: CGFloat = 240
#endif
    static let compactPosterWidth: CGFloat = 80
    static let compactPosterHeight: CGFloat = 140
    static let shadowRadius: CGFloat = 2
}
