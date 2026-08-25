//
//  EpisodeFrameView.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 10/05/22.
//

import SwiftUI
import NukeUI

/// A view that displays a frame with an image, episode number, title, and two line overview,
/// on tap it display a sheet view with more information.
struct EpisodeFrameView: View {
    let episode: Episode
    let season: Int
    let show: Int
    let showTitle: String
    private let persistence = PersistenceController.shared
    @State private var isWatched = false
    @State private var showDetails = false
    private let network = NetworkService.shared
    @Binding var checkedIfWatched: Bool
    @Binding var isInWatchlist: Bool
    @StateObject private var settings: SettingsStore = .shared
    let showCover: URL?
    @State private var showConfirmation = false
#if os(tvOS)
    @FocusState var isFocused
#endif
    var body: some View {
#if os(tvOS)
        VStack {
            Button {
                showDetails.toggle()
            } label: {
                image
                    .accessibilityElement(children: .combine)
                    .task {
                        withAnimation {
                            isWatched = persistence.isEpisodeSaved(show: show, season: season, episode: episode.id)
                        }
                    }
            }
            .buttonStyle(.card)
            information
        }
        .focused($isFocused)
        .padding(.top)
#else
        VStack {
            image
                .contextMenu {
                    WatchEpisodeButton(episode: episode,
                                       season: season,
                                       show: show,
                                       isWatched: $isWatched)
                    if SettingsStore.shared.markEpisodeWatchedOnTap {
                        Button("Show Details") {
                            showDetails.toggle()
                        }
                    }
                    
#if os(iOS) || os(macOS)
                    if let url = URL(string: "https://www.themoviedb.org/tv/\(show)/season/\(season)/episode/\(episode.itemEpisodeNumber)") {
                        ShareLink(item: url)
                    }
                    Divider()
                    if !isWatched {
                        Button("Mark This and Prior Episodes Watched", action: markThisAndAllPreviously)
                    }
#endif
                }
            information
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .task {
            withAnimation {
                isWatched = persistence.isEpisodeSaved(show: show, season: season, episode: episode.id)
            }
        }
        .onChange(of: checkedIfWatched) { _, check in
            if check {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation {
                        isWatched = persistence.isEpisodeSaved(show: show, season: season, episode: episode.id)
                    }
                }
            }
        }
#endif
    }
    
    private var information: some View {
        VStack {
            HStack {
                Text("Episode \(episode.itemEpisodeNumber)")
                    .font(.caption2)
                    .lineLimit(1)
#if !os(tvOS)
                    .foregroundColor(.secondary)
#else
                    .foregroundColor(isFocused ? .primary : .secondary)
#endif
                if let runtime = episode.itemRuntime {
                    Text("• \(runtime)")
                        .font(.caption2)
                        .lineLimit(1)
#if !os(tvOS)
                        .foregroundColor(.secondary)
#else
                        .foregroundColor(isFocused ? .primary : .secondary)
#endif
                }
                Spacer()
            }
            .padding(.top, 1)
            HStack {
                Text(episode.itemTitle)
                    .redacted(reason: isWatched ? [] : settings.hideEpisodesTitles ? .placeholder : [])
                    .font(.callout)
#if os(tvOS)
                    .foregroundColor(isFocused ? .primary : .secondary)
#endif
                    .lineLimit(1)
                Spacer()
            }
#if !os(tvOS)
            HStack {
                Text(episode.itemOverview)
                    .redacted(reason: isWatched ? [] : settings.hideEpisodesTitles ? .placeholder : [])
                    .font(.caption)
                    .lineLimit(2)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
                Spacer()
            }
#endif
            Spacer()
        }
    }
    
    private var image: some View {
        Button {
            if settings.markEpisodeWatchedOnTap, settings.askConfirmationToMarkEpisodeWatched {
                showConfirmation.toggle()
            } else if settings.markEpisodeWatchedOnTap, !settings.askConfirmationToMarkEpisodeWatched {
                markAsWatched()
            } else {
                showDetails.toggle()
            }
        } label: {
            EpisodeFrameImageView(episode: episode, isWatched: $isWatched, showCover: showCover)
                .transition(.opacity)
                .frame(width: DrawingConstants.imageWidth,
                       height: DrawingConstants.imageHeight)
                .clipShape(
                    RoundedRectangle(cornerRadius: DrawingConstants.imageRadius,
                                     style: .continuous)
                )
                .overlay {
                    if isWatched {
                        ZStack {
                            Color.black.opacity(0.4)
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: DrawingConstants.imageRadius, style: .continuous))
                        .frame(width: DrawingConstants.imageWidth,
                               height: DrawingConstants.imageHeight)
                        .accessibilityHidden(true)
                    }
                }
        }
        .buttonStyle(.plain)
        .applyHoverEffect()
        .sheet(isPresented: $showDetails) {
#if os(tvOS)
            EpisodeDetailsView(episode: episode,
                               season: season,
                               show: show,
                               showTitle: showTitle,
                               isWatched: $isWatched)
#else
            NavigationStack {
                EpisodeDetailsView(episode: episode, season: season, show: show, showTitle: showTitle, isWatched: $isWatched)
                    .nativeSheetDismissToolbar { showDetails = false }
            }
            .appTheme()
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
#if os(macOS)
            .frame(minWidth: 800, idealWidth: 800, minHeight: 600, idealHeight: 600, alignment: .center)
#endif
#endif
        }
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
        .confirmationDialog("Confirm Watched Episode",
                            isPresented: $showConfirmation, titleVisibility: .visible) {
            Button("Confirm") {
                markAsWatched()
            }
            Button("Cancel", role: .cancel) {
                showConfirmation = false
            }
        } message: {
            Text("Mark Episode \(episode.itemEpisodeNumber) from season \(episode.itemSeasonNumber) of \(showTitle) as Watched?")
        }
    }
    
    private func markAsWatched() {
        Task {
            let contentId = "\(show)@\(MediaType.tvShow.toInt)"
            let isItemInWatchlist = persistence.isItemSaved(id: contentId)
            if !isItemInWatchlist {
                return
            }
            persistence.updateEpisodeList(show: show, season: season, episode: episode.id)
            withAnimation { isWatched.toggle() }
            let nextEpisode = await EpisodeHelper().fetchNextEpisode(for: episode, show: show)
            if let nextEpisode {
                guard let item = persistence.fetch(for: contentId) else { return }
                persistence.updateUpNext(item, episode: nextEpisode)
            }
        }
    }
    
    private func addToWatchlist() async {
        guard let item = try? await NetworkService.shared.fetchItem(id: show, type: .tvShow) else { return }
        PersistenceController.shared.save(item)
        await MainActor.run {
            withAnimation { isInWatchlist.toggle() }
        }
    }
    
    private func markThisAndAllPreviously() {
        Task {
            var allEpisodes = [Episode]()
            var currentFetchedSeason = 1
            while (currentFetchedSeason <= season) {
                let seasonContent = try? await network.fetchSeason(id: show, season: currentFetchedSeason)
                if currentFetchedSeason == season {
                    if let episodes = seasonContent?.episodes {
                        for episode in episodes {
                            if episode.itemEpisodeNumber <= self.episode.itemEpisodeNumber {
                                allEpisodes.append(episode)
                            }
                        }
                    }
                } else {
                    if let episodes = seasonContent?.episodes {
                        allEpisodes.append(contentsOf: episodes)
                    }
                }
                currentFetchedSeason += 1
            }
            let contentId = "\(show)@\(MediaType.tvShow.toInt)"
            guard let listItem = persistence.fetch(for: contentId) else { return }
            persistence.updateEpisodeList(to: listItem, show: show, episodes: allEpisodes)
            checkedIfWatched = true
        }
    }
}

private struct EpisodeFrameImageView: View {
    let episode: Episode
    @Binding var isWatched: Bool
    let showCover: URL?
    @StateObject private var settings: SettingsStore = .shared
    var body: some View {
        LazyImage(url: isWatched ? episode.itemImageMedium : settings.hideEpisodesThumbnails ? showCover : episode.itemImageMedium) { state in
            if let image = state.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    Rectangle().fill(.gray.gradient)
                    VStack {
                        Spacer()
                        Text(episode.itemTitle)
                            .foregroundColor(.white.opacity(0.8))
                            .font(.body)
                            .fontDesign(.rounded)
                            .lineLimit(1)
                            .padding()
                        Spacer()
                    }
                    .padding()
                }
                .frame(width: DrawingConstants.imageWidth,
                       height: DrawingConstants.imageHeight)
                .accessibilityHidden(true)
            }
        }
    }
}

private struct DrawingConstants {
#if os(tvOS)
    static let imageWidth: CGFloat = 360
    static let imageHeight: CGFloat = 200
#else
    static let imageWidth: CGFloat = 200
    static let imageHeight: CGFloat = 120
#endif
    static let imageRadius: CGFloat = 12
    static let titleLineLimit: Int = 1
}
