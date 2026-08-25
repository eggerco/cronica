//
//  UpcomingWatchlist.swift
//  CronicaMac
//
//  Created by Alexandre Madeira on 03/11/22.
//

import SwiftUI
import NukeUI

struct UpcomingWatchlist: View {
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \WatchlistItem.date, ascending: true),
        ],
        predicate: NSCompoundPredicate(type: .or, subpredicates: [
            NSCompoundPredicate(type: .and,
                                subpredicates: [
                                    NSPredicate(format: "schedule == %d", ItemSchedule.soon.toInt),
                                    NSPredicate(format: "notify == %d", true),
                                    NSPredicate(format: "isArchive == %d", false),
                                    NSPredicate(format: "contentType == %d", MediaType.movie.toInt)
                                ])
            ,
            NSCompoundPredicate(type: .and,
                                subpredicates: [
                                    NSPredicate(format: "upcomingSeason == %d", true),
                                    NSPredicate(format: "isArchive == %d", false)
                                ])])
    )
    private var items: FetchedResults<WatchlistItem>
    @Binding var shouldReload: Bool
    var body: some View {
        list(items: items.filter {
            $0.backCompatibleCardImage != nil && $0.itemUpcomingReleaseDate > Date()
        }.sorted(by: {
            $0.itemUpcomingReleaseDate < $1.itemUpcomingReleaseDate
        }))
        .task {
            updateItems(items: items.filter { $0.itemReleaseDate < Date() })
        }
    }
    
    @ViewBuilder
    private func list(items: [WatchlistItem]) -> some View {
        if !items.isEmpty {
            VStack {
#if !os(tvOS) && !os(visionOS)
                HStack(alignment: .center) {
                    NavigationLink(value: items) {
                        TitleView(title: String(localized: "Upcoming"),
                                  subtitle: String(localized: "From Watchlist"),
                                  showChevron: items.count > 4 ? true : false)
                    }
                    .buttonStyle(.plain)
#if !os(watchOS)
                    Spacer()
                    NavigationLink(value: ReleaseCalendarRoute.watchlist) {
                        Image(systemName: "calendar")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .padding(.trailing, 16)
                            .accessibilityLabel("Release Calendar")
                    }
                    .buttonStyle(.plain)
#endif
                }
#else
                TitleView(title: String(localized: "Upcoming"),
                          subtitle: String(localized: "From Watchlist"),
                          showChevron: false)
#if os(tvOS)
                .padding(.leading, 64)
#endif
#endif
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack {
                            ForEach(items) { item in
                                UpNextCardView(item: item)
#if !os(tvOS)
                                    .padding(.leading, item.id == items.first?.id ? 16 : 0)
                                    .padding(.trailing, item.id == items.last?.id ? 16 : 0)
                                    .padding(.bottom)
                                    .padding(.top, 8)
                                    .padding([.leading, .trailing], 4)
                                    .buttonStyle(.plain)
#else
                                    .padding(.leading, item.id == items.first?.id ? 64 : 0)
                                    .padding(.trailing, item.id == items.last?.id ? 64 : 0)
                                    .padding(.vertical)
                                    .padding([.leading, .trailing], 4)
                                    .buttonStyle(.card)
#endif
                            }
                        }
                    }
                    .onChange(of: shouldReload) {
                        guard let firstItem = items.first else { return }
                        withAnimation {
                            proxy.scrollTo(firstItem.id, anchor: .topLeading)
                        }
                    }
                }
            }
        }
    }
}

extension UpcomingWatchlist {
    private func updateItems(items: [WatchlistItem]) {
        if items.isEmpty { return }
        Task {
            for item in items {
                if item.itemReleaseDate < Date() {
                    let content = try? await NetworkService.shared.fetchItem(id: item.itemId, type: item.itemMedia)
                    if let content {
                        PersistenceController.shared.update(item: content)
                    }
                }
            }
        }
    }
}

#Preview {
    UpcomingWatchlist(shouldReload: .constant(false))
}

private struct UpNextCardView: View {
    let item: WatchlistItem
    @StateObject private var settings = SettingsStore.shared
#if os(tvOS)
    @FocusState var isStackFocused: Bool
#endif
    var body: some View {
#if os(tvOS)
        VStack {
            UpComingCardImageView(item: item)
                .watchlistContextMenu(item: item,
                                      isWatched: .constant(false),
                                      isFavorite: .constant(false),
                                      isPin: .constant(false),
                                      isArchive: .constant(false),
                                      showNote: .constant(false),
                                      showCustomList: .constant(false),
                                      popupType: .constant(nil),
                                      showPopup: .constant(false))
                .buttonStyle(.card)
            HStack {
                Text(item.itemTitle)
                    .font(.caption)
                    .lineLimit(2)
#if os(tvOS)
                    .foregroundColor(isStackFocused ? .primary : .secondary)
#else
                    .foregroundColor(.secondary)
#endif
                Spacer()
            }
            if let info = item.itemGlanceInfo {
                HStack {
                    Text(info)
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            Spacer()
        }
        .frame(width: DrawingConstants.cardWidth)
#else
        if item.backCompatibleCardImage != nil {
            if settings.isCompactUI {
                VStack {
                    UpComingCardImageView(item: item)
                    HStack {
                        Text(item.itemTitle)
                            .font(.caption)
                            .lineLimit(2)
                        Spacer()
                    }
                    if let info = item.itemGlanceInfo {
                        HStack {
                            Text(info)
                                .font(.caption)
                                .lineLimit(1)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    Spacer()
                }
                .frame(width: DrawingConstants.compactCardWidth)
            } else {
                UpComingCardImageView(item: item)
            }
        } else {
            EmptyView()
        }
#endif
    }
}

private struct UpComingCardImageView: View {
    let item: WatchlistItem
    @StateObject private var settings = SettingsStore.shared
#if os(tvOS)
    @FocusState var isStackFocused: Bool
#endif
    var body: some View {
        NavigationLink(value: item) {
            LazyImage(url: item.backCompatibleCardImage) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    ZStack {
                        Rectangle().fill(.gray.gradient)
                        Image(systemName: "popcorn.fill")
                            .font(.title)
                            .fontWidth(.expanded)
                            .foregroundColor(.white.opacity(0.8))
                            .padding()
                    }
                }
            }
#if !os(tvOS)
            .overlay {
                if !settings.isCompactUI {
                    ZStack(alignment: .bottom) {
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .frame(height: 80)
                            .mask {
                                VStack(spacing: 0) {
                                    LinearGradient(colors: [Color.black.opacity(0),
                                                            Color.black.opacity(0.383),
                                                            Color.black.opacity(0.707),
                                                            Color.black.opacity(0.924),
                                                            Color.black],
                                                   startPoint: .top,
                                                   endPoint: .bottom)
                                    .frame(height: 60)
                                    Rectangle()
                                }
                            }
                            .environment(\.colorScheme, .dark)
                        if let info = item.itemGlanceInfo {
                            VStack(alignment: .leading) {
                                Spacer()
                                HStack {
                                    Text(item.itemTitle)
                                        .fontWeight(.semibold)
                                        .font(.callout)
                                        .foregroundColor(.white)
                                        .lineLimit(DrawingConstants.lineLimits)
                                        .padding(.leading)
                                    Spacer()
                                }
                                HStack {
                                    Text(info)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .lineLimit(DrawingConstants.lineLimits)
                                        .fontWeight(.medium)
                                        .padding(.leading)
                                        .padding(.bottom, 8)
                                    Spacer()
                                }
                            }
                            .padding(.horizontal, 2)
                        } else {
                            VStack(alignment: .leading) {
                                Spacer()
                                HStack {
                                    Text(item.itemTitle)
                                        .fontWeight(.semibold)
                                        .font(.callout)
                                        .foregroundColor(.white)
                                        .lineLimit(DrawingConstants.lineLimits)
                                        .padding()
                                    Spacer()
                                }
                                
                            }
                            .padding(.horizontal, 2)
                        }
                        
                    }
                }
            }
#endif
            .frame(width: settings.isCompactUI ? DrawingConstants.compactCardWidth : DrawingConstants.cardWidth,
                   height: settings.isCompactUI ? DrawingConstants.compactCardHeight : DrawingConstants.cardHeight)
            .clipShape(RoundedRectangle(cornerRadius: DrawingConstants.cardRadius, style: .continuous))
            .shadow(radius: DrawingConstants.shadowRadius)
            .transition(.opacity)
            .applyHoverEffect()
        }
#if os(tvOS)
        .focused($isStackFocused)
#endif
    }
}

private struct DrawingConstants {
#if os(tvOS)
    static let cardWidth: CGFloat = 420
    static let cardHeight: CGFloat = 240
#else
    static let cardWidth: CGFloat = 280
    static let cardHeight: CGFloat = 160
#endif
    static let cardRadius: CGFloat = 12
    static let shadowRadius: CGFloat = 2.5
    static let lineLimits: Int = 1
    static let compactCardWidth: CGFloat = 160
    static let compactCardHeight: CGFloat = 100
}
