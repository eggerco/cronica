//
//  ItemContentPosterView.swift
//  Cronica
//
//  Created by Alexandre Madeira on 17/01/22.
//

import SwiftUI
import NukeUI

struct ItemContentPosterView: View {
    let item: ItemContent
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
    var body: some View {
        NavigationLink(value: item) {
            if settings.isCompactUI {
                compact
            } else {
                image
            }
        }
#if os(tvOS)
        .buttonStyle(.card)
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
#else
        .buttonStyle(.plain)
#endif
        .accessibility(label: Text(item.itemTitle))
    }
    
    private var image: some View {
        LazyImage(url: item.posterImageMedium) { state in
            if let image = state.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                PosterPlaceholder(title: item.itemTitle, type: item.itemContentMedia)
            }
        }
        .overlay {
            if isInWatchlist {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
#if !os(tvOS)
                        if !settings.isCompactUI {
                            if isArchive {
                                Image(systemName: "archivebox.fill")
                                    .imageScale(.small)
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding([.vertical])
#if !os(tvOS)
                                    .padding(.trailing, 4)
#else
                                    .padding(.trailing, 2)
                                    .font(.caption)
#endif
                            }
                            if isPin {
                                Image(systemName: "pin.fill")
                                    .imageScale(.small)
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding([.vertical])
#if !os(tvOS)
                                    .padding(.trailing, 4)
#else
                                    .padding(.trailing, 2)
                                    .font(.caption)
#endif
                            }
                        }
                        if isFavorite {
                            Image(systemName: "suit.heart.fill")
                                .imageScale(.small)
                                .foregroundColor(.white.opacity(0.9))
                                .padding([.vertical])
#if !os(tvOS)
                                .padding(.trailing, 4)
#else
                                .padding(.trailing, 2)
                                .font(.caption)
#endif
                        }
#endif
                        if isWatched {
                            Image(systemName: "rectangle.badge.checkmark.fill")
                                .imageScale(.small)
                                .foregroundColor(.white.opacity(0.9))
                                .padding([.vertical])
#if !os(tvOS)
                                .padding(.trailing, 4)
#else
                                .padding(.trailing, 2)
                                .font(.caption)
#endif
                        }
                        Image(systemName: "square.stack.fill")
                            .imageScale(.small)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.vertical)
#if !os(tvOS)
                            .padding(.trailing)
#else
                            .padding(.horizontal)
                            .font(.caption)
#endif
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
                .frame(width: settings.isCompactUI ? DrawingConstants.compactPosterWidth : DrawingConstants.posterWidth)
            }
        }
        .transition(.opacity)
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
#endif
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
                                          title: item.itemTitle, image: item.posterImageMedium)
        }
    }
    
    private var compact: some View {
        VStack(alignment: .leading) {
            image
            HStack {
                Text("\(item.itemTitle)\n")
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
    ItemContentPosterView(item: .example, showPopup: .constant(false), popupType: .constant(nil))
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
}
