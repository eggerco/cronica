//
//  FeaturedHomeSectionView.swift
//  Cronica
//

import SwiftUI
import NukeUI

struct FeaturedHomeSectionView: View {
    let items: [ItemContent]
    let title: String
    let subtitle: String
    @Binding var showPopup: Bool
    @Binding var popupType: ActionPopupItems?

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
#if os(tvOS)
                TitleView(title: title, subtitle: subtitle)
                    .padding(.leading, 64)
#else
                NavigationLink(value: [title: items]) {
                    TitleView(title: title, subtitle: subtitle, showChevron: items.count > 4)
                }
                .buttonStyle(.plain)
#endif
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: 16) {
                        ForEach(items) { item in
                            FeaturedItemCardView(
                                item: item,
                                showPopup: $showPopup,
                                popupType: $popupType
                            )
                            .padding(.leading, item.id == items.first?.id ? 16 : 0)
                            .padding(.trailing, item.id == items.last?.id ? 16 : 0)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom)
                }
                .accessibilityIdentifier("Featured Horizontal List")
            }
        }
    }
}

private struct FeaturedItemCardView: View {
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

    var body: some View {
        NavigationLink(value: item) {
            VStack(alignment: .leading, spacing: 10) {
                poster
                Text(item.itemTitle)
                    .font(.subheadline.weight(.semibold))
                    .fontDesign(.rounded)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                if let overview = trimmedOverview {
                    Text(overview)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .frame(width: FeaturedDrawingConstants.cardWidth, alignment: .leading)
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
            ItemContentCustomListSelector(
                contentID: item.itemContentID,
                showView: $showCustomListView,
                title: item.itemTitle,
                image: item.posterImageMedium
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(item.itemTitle))
    }

    private var poster: some View {
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
                WatchlistPosterStatusOverlay(isWatched: isWatched)
            }
        }
        .frame(width: FeaturedDrawingConstants.cardWidth, height: FeaturedDrawingConstants.posterHeight)
        .clipShape(RoundedRectangle(cornerRadius: FeaturedDrawingConstants.cornerRadius, style: .continuous))
        .shadow(color: .black.opacity(0.22), radius: 8, y: 5)
    }

    private var trimmedOverview: String? {
        let overview = item.itemOverview?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return overview.isEmpty ? nil : overview
    }
}

private enum FeaturedDrawingConstants {
#if os(tvOS)
    static let cardWidth: CGFloat = 260
    static let posterHeight: CGFloat = 390
#else
    static let cardWidth: CGFloat = 200
    static let posterHeight: CGFloat = 300
#endif
    static let cornerRadius: CGFloat = 16
}

#Preview {
    ScrollView {
        FeaturedHomeSectionView(
            items: ItemContent.examples,
            title: String(localized: "Featured"),
            subtitle: String(localized: "Popular and trending titles"),
            showPopup: .constant(false),
            popupType: .constant(nil)
        )
    }
}
