//
//  ItemContentFrameView.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 07/06/22.
//

import SwiftUI
import NukeUI

struct ItemContentCardView: View {
    let item: ItemContent
    @Binding var showPopup: Bool
    @Binding var popupType: ActionPopupItems?
    private let context = PersistenceController.shared
    @State private var isInWatchlist = false
    @State private var isWatched = false
    @State private var isPin = false
    @State private var isFavorite = false
    @State private var isArchive = false
    @State private var showNote = false
    @State private var showCustomListView = false
#if os(tvOS)
    @FocusState var isStackFocused: Bool
#endif
    var body: some View {
        VStack {
            NavigationLink(value: item) {
                LazyImage(url: item.cardImageMedium) { state in
                    if let image = state.image {
                        image
                            .resizable()
                    } else {
                        ZStack {
                            Rectangle().fill(.gray.gradient)
                            Image(systemName: "popcorn")
                                .foregroundColor(DrawingConstants.placeholderForegroundColor)
                                .padding()
                        }
                        .frame(width: DrawingConstants.imageWidth,
                               height: DrawingConstants.imageHeight)
                        .clipShape(RoundedRectangle(cornerRadius: CronicaDesign.Radius.media, style: .continuous))
                    }
                }
                .overlay {
                    if isInWatchlist {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                if isArchive {
                                    Image(systemName: "archivebox")
                                        .imageScale(.small)
                                        .foregroundColor(.white.opacity(0.9))
                                        .padding([.vertical])
                                        .padding(.trailing, 4)
                                }
                                if isPin {
                                    Image(systemName: "pin")
                                        .imageScale(.small)
                                        .foregroundColor(.white.opacity(0.9))
                                        .padding([.vertical])
                                        .padding(.trailing, 4)
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
                                if item.cardImageMedium != nil {
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
                .aspectRatio(contentMode: .fill)
                .transition(.opacity)
                .frame(width: DrawingConstants.imageWidth,
                       height: DrawingConstants.imageHeight)
                .clipShape(RoundedRectangle(cornerRadius: CronicaDesign.Radius.media,
                                            style: .continuous))
                .shadow(
                    color: .black.opacity(CronicaDesign.Shadow.mediaOpacity),
                    radius: CronicaDesign.Shadow.mediaRadius,
                    x: 0,
                    y: CronicaDesign.Shadow.mediaY
                )
                .applyHoverEffect()
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
#endif
            HStack {
                Text(item.itemTitle)
                    .font(.caption)
                    .lineLimit(DrawingConstants.titleLineLimit)
                    .accessibilityHidden(true)
#if os(tvOS)
                    .foregroundColor(isStackFocused ? .primary : .secondary)
                    .padding(.vertical, 4)
#endif
                Spacer()
            }
            .frame(width: DrawingConstants.imageWidth)
            Spacer()
        }
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
#if os(tvOS)
        .focused($isStackFocused)
#endif
        .sheet(isPresented: $showNote) {
            ReviewView(id: item.itemContentID, showView: $showNote)
        }
        .sheet(isPresented: $showCustomListView) {
            ItemContentCustomListSelector(contentID: item.itemContentID,
                                          showView: $showCustomListView,
                                          title: item.itemTitle, image: item.posterImageMedium)
        }
        .accessibilityLabel(Text(item.itemTitle))
    }
}

#Preview {
    ItemContentCardView(item: .example, showPopup: .constant(false), popupType: .constant(nil))
}

private struct DrawingConstants {
#if os(macOS) || os(visionOS)
    static let imageWidth: CGFloat = 240
    static let imageHeight: CGFloat = 140
#elseif os(tvOS)
    static let imageWidth: CGFloat = 420
    static let imageHeight: CGFloat = 240
#elseif os(iOS)
    static let imageWidth: CGFloat = UIDevice.isIPad ? 240 : 160
    static let imageHeight: CGFloat = UIDevice.isIPad ? 140 : 100
#endif
    static let titleLineLimit: Int = 2
    static let placeholderForegroundColor: Color = .white.opacity(0.8)
}
