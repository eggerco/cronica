//
//  EpisodeDetailsView.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 20/06/22.
//
import SwiftUI
import NukeUI

struct EpisodeDetailsView: View {
    let episode: Episode
    let season: Int
    let show: Int
    let showTitle: String
    private let persistence = PersistenceController.shared
    @Binding var isWatched: Bool
    @State private var isInWatchlist = false
    @State private var showOverview = false
    @StateObject private var settings = SettingsStore.shared
    var isUpNext = false
    @State private var showItem: ItemContent?
    @State private var showPopup = false
    @State private var popupType: ActionPopupItems?
#if os(iOS)
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
#endif
    var body: some View {
        details
            .actionPopup(isShowing: $showPopup, for: popupType)
            .onChange(of: isWatched) { _, hasWatched in
                if isUpNext { return }
                if hasWatched {
                    popupType = .markedEpisodeWatched
                    showPopup = true
                } else {
                    popupType = .removedEpisodeWatched
                    showPopup = true
                }
            }
    }
    
#if os(tvOS)
    private var details: some View {
        EpisodeDetailsTVView(episode: episode, season: season, show: show, isWatched: $isWatched)
    }
#endif
    
#if os(iOS) || os(macOS) || os(visionOS)
    private var details: some View {
        ScrollView {
            VStack {
                HeroImage(url: episode.itemImageLarge, title: episode.itemTitle)
#if os(macOS) || os(visionOS)
                    .frame(width: DrawingConstants.padImageWidth,
                           height: DrawingConstants.padImageHeight)
#else
                    .frame(width: (horizontalSizeClass == .regular) ? DrawingConstants.padImageWidth : DrawingConstants.imageWidth,
                           height: (horizontalSizeClass == .compact) ? DrawingConstants.imageHeight : DrawingConstants.padImageHeight)
#endif
                    .clipShape(RoundedRectangle(cornerRadius: DrawingConstants.imageRadius, style: .continuous))
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 10)
#if os(macOS)
                    .padding(.top)
#endif
                
                
                if let info = episode.itemInfo {
                    Text(episode.itemTitle)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.top, 8)
                        .padding(.horizontal)
                        .padding(.bottom, 0.5)
                        .multilineTextAlignment(.center)
                    Text(showTitle)
                        .multilineTextAlignment(.center)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    if !info.isEmpty {
                        CenterHorizontalView {
                            Text(info)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }
                }
                
                HStack {
                    WatchEpisodeButton(episode: episode,
                                       season: season,
                                       show: show,
                                       isWatched: $isWatched)
                    .buttonStyle(.borderedProminent)
#if os(iOS)
                    .buttonBorderShape(.roundedRectangle(radius: 12))
                    .padding(isUpNext ? .leading : .horizontal)
                    .tint(settings.appTheme.color)
#elseif os(macOS)
                    .padding(.horizontal)
                    .controlSize(.large)
                    .tint(isWatched ? .red : .blue)
#endif
                    .keyboardShortcut("e", modifiers: [.control])
                    .shadow(radius: isUpNext ? 0 : 2.5)
                }
                .padding(.top, 4)
                .padding(.bottom)
                
                OverviewBoxView(overview: episode.itemOverview,
                                title: episode.itemTitle,
                                type: .tvShow)
                .padding([.horizontal, .bottom])
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .task { load() }
#if !os(visionOS)
        .background {
            TranslucentBackground(image: episode.itemImageLarge)
        }
#endif
        .onAppear {
            if isUpNext, showItem == nil {
                Task {
                    showItem = try await NetworkService.shared.fetchItem(id: show, type: .tvShow)
                }
            }
        }
#if os(iOS)
        .toolbar {
            if horizontalSizeClass == .compact {
                ToolbarItem(placement: .topBarTrailing) {
                    if let showItem {
                        NavigationLink(value: showItem) {
                            Label("More Info", systemImage: "info.circle")
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle(Text(String()))
#endif
    }
#endif
}

private struct DrawingConstants {
    static let titleLineLimit: Int = 1
    static let shadowRadius: CGFloat = 12
    static let imageWidth: CGFloat = 360
    static let imageHeight: CGFloat = 210
    static let imageRadius: CGFloat = 12
    static let padImageWidth: CGFloat = 500
    static let padImageHeight: CGFloat = 300
    static let padImageRadius: CGFloat = 12
}

extension EpisodeDetailsView {
    private func load() {
        isWatched = persistence.isEpisodeSaved(show: show, season: season, episode: episode.id)
    }
    
    private func checkIfItemIsSaved() {
        let contentId = "\(show)@\(MediaType.tvShow.toInt)"
        let isShowSaved = persistence.isItemSaved(id: contentId)
        isInWatchlist = isShowSaved
    }
}

private struct EpisodeDetailsTVView: View {
    let episode: Episode
    let season: Int
    let show: Int
    @Binding var isWatched: Bool
    var body: some View {
        ZStack {
            LazyImage(url: episode.itemImageOriginal) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            }
            .frame(width: 1920, height: 1080)
            VStack {
                Spacer()
                ZStack {
                    Color.black.opacity(0.4)
                        .frame(height: 400)
                        .mask {
                            LinearGradient(colors: [Color.black,
                                                    Color.black.opacity(0.924),
                                                    Color.black.opacity(0.707),
                                                    Color.black.opacity(0.383),
                                                    Color.black.opacity(0)],
                                           startPoint: .bottom,
                                           endPoint: .top)
                        }
                    Rectangle()
                        .fill(.regularMaterial)
                        .frame(height: 600)
                        .mask {
                            VStack(spacing: 0) {
                                LinearGradient(colors: [Color.black.opacity(0),
                                                        Color.black.opacity(0.383),
                                                        Color.black.opacity(0.707),
                                                        Color.black.opacity(0.924),
                                                        Color.black],
                                               startPoint: .top,
                                               endPoint: .bottom)
                                .frame(height: 400)
                                Rectangle()
                            }
                        }
                }
            }
            .padding(.zero)
            .ignoresSafeArea()
            .frame(width: 1920, height: 1080)
            VStack(alignment: .leading) {
                Spacer()
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading) {
                        Text(episode.itemTitle)
                            .lineLimit(1)
                            .font(.title3)
                        WatchEpisodeButton(episode: episode,
                                           season: season,
                                           show: show,
                                           isWatched: $isWatched)
                        .tint(.primary)
                        .padding(.horizontal)
                    }
                    .padding()
                    Spacer()
                    VStack(alignment: .leading) {
                        HStack {
                            InfoSegmentView(title: String(localized: "Episode"),
                                            info: "\(episode.itemEpisodeNumber)")
                            InfoSegmentView(title: String(localized: "Season"),
                                            info: "\(episode.itemSeasonNumber)")
                        }
                        InfoSegmentView(title: String(localized: "Release"), info: episode.itemDate)
                    }
                    .padding()
                }
                .padding()
            }
            .padding()
        }
    }
}
