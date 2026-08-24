//
//  SeasonListView.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 02/04/22.
//

import SwiftUI

struct SeasonListView: View {
    let showID: Int
    let showTitle: String
    var seasons: [Season]
    @State private var lastSelectedSeason = 0
    @State private var selectedSeason = 1
    @State private var hasFirstLoaded = false
    @State private var isLoading = true
    @State private var previouslySelectedSeason = 1
    @State private var season: Season?
    @State private var checkIfWatched = false
    @Binding var isInWatchlist: Bool
    private let persistence = PersistenceController.shared
    private let network = NetworkService.shared
    let showCover: URL?
    @State private var selectedSeasonDetails: Season?
    
    var body: some View {
        VStack {
#if !os(watchOS)
            header
            if isLoading {
                HStack(alignment: .center) {
                    ProgressView().padding()
                }
                .frame(maxWidth: .infinity)
            } else {
                if let season = season?.episodes {
                    if season.isEmpty {
                        HStack {
                            Spacer()
                            VStack {
                                Image(systemName: "tv.fill")
                                    .font(.title)
                                    .padding(.bottom, 6)
                                Text("No Episode Available")
                            }
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            Spacer()
                        }
                        .padding(.horizontal)
                    } else {
                        ScrollViewReader { proxy in
                            ScrollView(.horizontal) {
                                LazyHStack {
                                    ForEach(season) { item in
                                        EpisodeFrameView(episode: item,
                                                         season: selectedSeason,
                                                         show: showID,
                                                         showTitle: showTitle,
                                                         checkedIfWatched: $checkIfWatched, isInWatchlist: $isInWatchlist,
                                                         showCover: showCover)
                                        .tag(item.id)
#if os(tvOS)
                                        .frame(width: 360)
                                        .padding([.leading, .trailing], 2)
                                        .padding(.leading, item.id == season.first?.id ? 64 : 0)
                                        .padding(.trailing, item.id == season.last?.id ? 64 : 0)
#else
                                        .frame(width: 200)
                                        .padding([.leading, .trailing], 4)
                                        .padding(.leading, item.id == season.first?.id ? 16 : 0)
                                        .padding(.trailing, item.id == season.last?.id ? 16 : 0)
#endif
                                        
                                    }
                                }
                                .padding(.top, 8)
                                .onAppear {
                                    if !hasFirstLoaded { return }
                                    let lastWatchedEpisode = persistence.fetchLastWatchedEpisode(for: showID)
                                    guard let lastWatchedEpisode else { return }
                                    withAnimation {
                                        proxy.scrollTo(lastWatchedEpisode, anchor: .topLeading)
                                    }
                                }
                                .onChange(of: hasFirstLoaded) {
                                    if hasFirstLoaded {
                                        let lastWatchedEpisode = persistence.fetchLastWatchedEpisode(for: showID)
                                        guard let lastWatchedEpisode else { return }
                                        withAnimation {
                                            proxy.scrollTo(lastWatchedEpisode, anchor: .topLeading)
                                        }
                                    }
                                }
                                .onChange(of: selectedSeason) {
                                    if !hasFirstLoaded { return }
                                    guard let first = season.first else { return }
                                    withAnimation { proxy.scrollTo(first.id, anchor: .topLeading) }
                                }
                            }
                            .scrollIndicators(.hidden)
                        }
                    }
                }
            }
#else
            ScrollViewReader { proxy in
                VStack {
                    if isLoading {
                        ProgressView("Loading")
                    } else {
                        if let season = season?.episodes {
                            List {
                                ForEach(season) { episode in
                                    NavigationLink(value: [showID:episode]) {
                                        EpisodeRow(episode: episode,
                                                   season: selectedSeason,
                                                   show: showID)
                                    }
                                }
                            }
                            .onAppear {
                                guard let lastWatched = PersistenceController.shared.fetchLastWatchedEpisode(for: showID) else { return }
                                withAnimation { proxy.scrollTo(lastWatched, anchor: .topLeading) }
                            }
                        }
                        
                    }
                }
                .navigationTitle(showTitle)
                .navigationBarTitleDisplayMode(.inline)
            }
#endif
        }
        .sheet(item: $selectedSeasonDetails) { item in
            SeasonDetailView(item: item, showID: showID, selectedSeasonDetails: $selectedSeasonDetails)
        }
        .task {
            if !hasFirstLoaded { await load() }
        }
#if os(tvOS)
        .ignoresSafeArea(.all, edges: .horizontal)
#elseif os(watchOS)
        .toolbar {
            if seasons.count > 1 {
                ToolbarItem(placement: .bottomBar) {
                    seasonPicker
                        .pickerStyle(.navigationLink)
                }
            }
        }
#endif
    }
    
    private var seasonPicker: some View {
        Picker(selection: $selectedSeason) {
            ForEach(self.seasons, id: \.self) { item in
#if os(watchOS)
                Text("Season \(item.seasonNumber)")
                    .tag(item.seasonNumber)
                    .fontWeight(.semibold)
                    .padding()
#else
                if let name = item.name {
                    Text(name)
                        .lineLimit(1)
                        .tag(item.seasonNumber)
                } else {
                    Text("Season \(item.seasonNumber)").tag(item.seasonNumber)
                }
#endif
            }
        } label: {
#if os(iOS) || os(tvOS)
            Text("Season")
                .lineLimit(1)
#endif
        }
#if os(macOS)
        .pickerStyle(.automatic)
#elseif os(iOS)
        .pickerStyle(.menu)
#endif
        .onChange(of: selectedSeason) {
            Task {
                await load()
                checkIfWatched = false
            }
        }
        .padding(.leading)
        .padding(.bottom, 1)
        .unredacted()
    }
    
    private var header: some View {
        HStack {
#if os(tvOS)
            Menu {
                seasonPicker
                    .pickerStyle(.inline)
            } label: {
                Text("Season \(selectedSeason)")
            }
            .padding(.horizontal, 60)
#else
            seasonPicker
#if os(macOS)
                .frame(maxWidth: 200)
#endif
#endif
            Spacer()
#if !os(watchOS)
            Menu {
                Button("Show Season Details") {
                    selectedSeasonDetails = season
                }
#if os(iOS)
                if let url = URL(string: "https://www.themoviedb.org/tv/\(showID)/season/\(selectedSeason)") {
                    ShareLink(item: url)
                }
#endif
                Divider()
                if isInWatchlist { Button("Mark This Season as Watched", action: markSeasonAsWatched) }
            } label: {
                Label("More", systemImage: "ellipsis.circle")
                    .labelStyle(.iconOnly)
            }
#if os(macOS)
            .menuStyle(.borderlessButton)
            .frame(width: 40)
#elseif os(visionOS)
            .menuStyle(.borderlessButton)
#endif
#if os(tvOS)
            .padding(.horizontal, 60)
#else
            .padding(.horizontal)
#endif
#endif
        }
    }
}

extension SeasonListView {
    private func load() async {
        let contentId = "\(showID)@\(MediaType.tvShow.toInt)"
        let isShowSaved = persistence.isItemSaved(id: contentId)
        if !hasFirstLoaded && isShowSaved {
            let lastPickedSeason = persistence.getLastSelectedSeason(contentId)
            guard let lastPickedSeason else {
                self.lastSelectedSeason = 1
                return
            }
            self.previouslySelectedSeason = lastPickedSeason
            self.selectedSeason = lastPickedSeason
            self.lastSelectedSeason = lastPickedSeason
            await fetch(season: lastSelectedSeason)
        } else if previouslySelectedSeason != selectedSeason {
            await fetch(season: selectedSeason)
            previouslySelectedSeason = selectedSeason
        } else {
            if hasFirstLoaded && lastSelectedSeason == selectedSeason { return }
            await fetch(season: selectedSeason)
            previouslySelectedSeason = selectedSeason
        }
        self.hasFirstLoaded = true
    }
    
    private func fetch(season: Int) async {
        do {
            if Task.isCancelled { return }
            withAnimation { isLoading = true }
            self.season = try await network.fetchSeason(id: showID, season: season)
            withAnimation { isLoading = false }
        } catch {
            if Task.isCancelled { return }
            let message = "Season \(season), id: \(showID), error: \(error.localizedDescription)"
            CronicaTelemetry.shared.handleMessage(message, for: "SeasonViewModel.load.failed")
            withAnimation { isLoading = false }
        }
    }
    
    private func markSeasonAsWatched() {
        guard let episodes = season?.episodes else { return }
        let contentID = "\(showID)@\(MediaType.tvShow.toInt)"
        guard let item = persistence.fetch(for: contentID) else { return }
        persistence.updateEpisodeList(to: item, show: showID, episodes: episodes)
        Task {
            guard let actualSeason = season?.seasonNumber else { return }
            let nextSeason = actualSeason + 1
            let nextSeasonContent = try? await network.fetchSeason(id: showID, season: nextSeason)
            if let firstEpisode = nextSeasonContent?.episodes?.first {
                if !persistence.isEpisodeSaved(show: showID, season: nextSeason, episode: firstEpisode.id) {
                    persistence.updateUpNext(item, episode: firstEpisode)
                }
            }
        }
        checkIfWatched = true
    }
}
