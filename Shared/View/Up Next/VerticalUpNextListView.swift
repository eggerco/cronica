//
//  VerticalUpNextListView.swift
//  Cronica
//
//  Created by Alexandre Madeira on 07/05/23.
//

import SwiftUI
import NukeUI

struct VerticalUpNextListView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WatchlistItem.title, ascending: true)],
        predicate: NSCompoundPredicate(type: .and, subpredicates: [ NSPredicate(format: "displayOnUpNext == %d", true),
                                                                    NSPredicate(format: "isArchive == %d", false),
                                                                    NSPredicate(format: "watched == %d", false)]),
        animation: .default
    ) private var items: FetchedResults<WatchlistItem>
    @EnvironmentObject var viewModel: UpNextViewModel
    @State private var selectedEpisode: UpNextEpisode?
    @State private var query = String()
    @State private var queryResult = [UpNextEpisode]()
    @StateObject private var settings = SettingsStore.shared
    @Environment(\.scenePhase) private var scene
    var body: some View {
        ZStack {
            switch settings.upNextStyle {
            case .list: listStyle
            case .card: cardStyle
            }
        }
        .onChange(of: scene) { _, value in
            if scene == .active {
                Task {
                    await viewModel.checkForNewEpisodes(items)
                }
            }
        }
        .overlay {
            if queryResult.isEmpty, !query.isEmpty {
                SearchContentUnavailableView(query: query)
            }
        }
        .cronicaLoadingOverlay(!viewModel.isLoaded && query.isEmpty)
#if os(iOS)
        .searchable(text: $query,
                    placement: UIDevice.isIPhone ? .navigationBarDrawer(displayMode: .always) : .toolbar)
#elseif os(macOS)
        .searchable(text: $query, placement: .toolbar)
#endif
        .sheet(item: $selectedEpisode) { item in
            NavigationStack {
                EpisodeDetailsView(episode: item.episode,
                                   season: item.episode.itemSeasonNumber,
                                   show: item.showID,
                                   showTitle: item.showTitle,
                                   isWatched: $viewModel.isWatched,
                                   isUpNext: true)
                .nativeSheetDismissToolbar { self.selectedEpisode = nil }
                .cronicaStandardNavigationDestinations()
            }
#if os(macOS)
            .frame(minWidth: 800, idealWidth: 800, minHeight: 600, idealHeight: 600, alignment: .center)
#elseif os(iOS)
            .appTheme()
            .appTint()
            .presentationDragIndicator(.visible)
            .presentationDetents([.large])
#endif
        }
        .task(id: viewModel.isWatched) {
            if viewModel.isWatched {
                await viewModel.handleWatched(selectedEpisode)
                self.selectedEpisode = nil
                if !query.isEmpty {
                    withAnimation {
                        queryResult.removeAll()
                        query = String()
                    }
                }
            }
        }
        .task { await viewModel.checkForNewEpisodes(items) }
        .autocorrectionDisabled()
        .task(id: query) { search() }
        .navigationTitle("Up Next")
    }
    
    private var listStyle: some View {
        Form {
            Section {
                List {
                    if !queryResult.isEmpty {
                        ForEach(queryResult) { item in
                            VerticalUpNextListRowView(item: item, selectedEpisode: $selectedEpisode)
                                .environmentObject(viewModel)
                        }
                    } else if queryResult.isEmpty && !query.isEmpty {
                        EmptyView()
                    } else {
                        ForEach(viewModel.episodes) { item in
                            VerticalUpNextListRowView(item: item, selectedEpisode: $selectedEpisode)
                                .environmentObject(viewModel)
                        }
                    }
                }
                .refreshable {
                    Task { await viewModel.reload(items) }
                }
                .redacted(reason: viewModel.isLoaded ? [] : .placeholder)
            }
        }
#if os(macOS)
        .formStyle(.grouped)
#endif
    }
    
    private var cardStyle: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVGrid(columns: DrawingConstants.columns, spacing: 20) {
                    if !queryResult.isEmpty {
                        ForEach(queryResult) { item in
                            VStack(alignment: .leading) {
                                VerticalUpNextCardView(item: item, selectedEpisode: $selectedEpisode)
                                    .environmentObject(viewModel)
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(item.showTitle)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .lineLimit(2)
                                        Text(String(format: NSLocalizedString("S%d, E%d", comment: ""), item.episode.itemSeasonNumber, item.episode.itemEpisodeNumber))
                                            .font(.caption)
                                            .textCase(.uppercase)
                                            .fontWeight(.medium)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                }
                                .frame(width: DrawingConstants.imageWidth)
                                Spacer()
                            }
                        }
                    } else if queryResult.isEmpty && !query.isEmpty {
                        ContentUnavailableView.search(text: query)
                    } else {
                        ForEach(viewModel.episodes) { item in
                            VStack(alignment: .leading) {
                                VerticalUpNextCardView(item: item, selectedEpisode: $selectedEpisode)
                                    .environmentObject(viewModel)
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(item.showTitle)
                                            .font(.caption)
                                            .lineLimit(2)
                                        Text(String(format: NSLocalizedString("S%d, E%d", comment: ""), item.episode.itemSeasonNumber, item.episode.itemEpisodeNumber))
                                            .font(.caption)
                                            .textCase(.uppercase)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                }
                                .frame(width: DrawingConstants.imageWidth)
                                Spacer()
                            }
                        }
                    }
                }
                .onChange(of: viewModel.isWatched) {
                    guard let first = viewModel.episodes.first else { return }
                    if viewModel.isWatched {
                        withAnimation {
                            proxy.scrollTo(first.id, anchor: .topLeading)
                        }
                    }
                }
                .padding()
            }
            .refreshable {
                Task { await viewModel.reload(items) }
            }
            .redacted(reason: viewModel.isLoaded ? [] : .placeholder)
            .scrollBounceBehavior(.basedOnSize)
        }
    }
    
    private func search() {
        if query.isEmpty && !queryResult.isEmpty {
            withAnimation {
                queryResult.removeAll()
            }
        } else {
            queryResult.removeAll()
            queryResult = viewModel.episodes.filter{ $0.showTitle.lowercased().contains(query.lowercased())}
        }
    }
}

private struct DrawingConstants {
#if os(iOS)
    static let columns = [GridItem(.adaptive(minimum: 160))]
    static let imageWidth: CGFloat = 160
    static let imageHeight: CGFloat = 100
#else
    static let columns = [GridItem(.adaptive(minimum: 280))]
    static let imageWidth: CGFloat = 280
    static let imageHeight: CGFloat = 160
#endif
    static let imageRadius: CGFloat = 12
    static let titleLineLimit: Int = 1
    static let imageShadow: CGFloat = 2.5
}
