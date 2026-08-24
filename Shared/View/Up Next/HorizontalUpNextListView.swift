//
//  HorizontalUpNextListView.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 19/03/23.
//

import SwiftUI
import NukeUI

struct HorizontalUpNextListView: View {
    @Binding var shouldReload: Bool
    @State private var selectedEpisode: UpNextEpisode?
    @StateObject private var settings = SettingsStore.shared
    @StateObject private var viewModel = UpNextViewModel.shared
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WatchlistItem.title, ascending: true)],
        predicate: NSCompoundPredicate(type: .and, subpredicates: [ NSPredicate(format: "displayOnUpNext == %d", true),
                                                                    NSPredicate(format: "isArchive == %d", false),
                                                                    NSPredicate(format: "watched == %d", false)]),
        animation: .default
    ) private var items: FetchedResults<WatchlistItem>
    @Environment(\.scenePhase) private var scene
    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading) {
                if !viewModel.episodes.isEmpty {
#if os(tvOS) || os(visionOS)
                    TitleView(title: String(localized: "Up Next"),
                              subtitle: String(localized: "Your Next Episodes"),
                              showChevron: false)
#if os(tvOS)
                    .padding(.leading, 64)
#endif
#else
                    
                    if viewModel.episodes.count > 4 {
                        NavigationLink(value: viewModel.episodes) {
                            TitleView(title: String(localized: "Up Next"),
                                      subtitle: String(localized: "Your Next Episodes"),
                                      showChevron: true)
                            .unredacted()
                        }
                        .disabled(!viewModel.isLoaded)
                        .buttonStyle(.plain)
                    } else {
                        TitleView(title: String(localized: "Up Next"),
                                  subtitle: String(localized: "Your Next Episodes"),
                                  showChevron: false)
                        .unredacted()
                    }
                    
#endif
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack {
                                ForEach(viewModel.episodes) { item in
#if os(tvOS)
                                    UpNextCard(item: item, selectedEpisode: $selectedEpisode)
                                        .padding([.leading, .trailing], 4)
                                        .padding(.leading, item.id == viewModel.episodes.first?.id ? 64 : 0)
                                        .padding(.trailing, item.id == viewModel.episodes.last?.id ? 64 : 0)
                                        .padding(.top, 8)
                                        .padding(.bottom)
                                        .buttonStyle(.card)
                                        .environmentObject(viewModel)
#else
                                    
                                    
                                    VStack(alignment: .leading) {
                                        UpNextCard(item: item, selectedEpisode: $selectedEpisode)
                                            .buttonStyle(.plain)
                                            .environmentObject(viewModel)
                                            .frame(width: settings.isCompactUI ? DrawingConstants.compactImageWidth : DrawingConstants.imageWidth,
                                                   height: settings.isCompactUI ? DrawingConstants.compactImageHeight : DrawingConstants.imageHeight)
                                            .clipShape(RoundedRectangle(cornerRadius: DrawingConstants.imageRadius, style: .continuous))
                                            .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 5)
                                            .accessibilityLabel("Episode: \(item.episode.itemEpisodeNumber), of the show: \(item.showTitle).")
                                            .accessibilityAddTraits(.isButton)
                                            .applyHoverEffect()
                                            .padding([.leading, .trailing], 4)
                                            .padding(.leading, item.id == viewModel.episodes.first?.id ? 16 : 0)
                                            .padding(.trailing, item.id == viewModel.episodes.last?.id ? 16 : 0)
                                            .padding(.top, 8)
                                            .padding(.bottom, settings.isCompactUI ? .zero : nil)
                                        if settings.isCompactUI {
                                            HStack {
                                                VStack(alignment: .leading) {
                                                    Text(item.showTitle)
                                                        .font(.caption)
                                                        .lineLimit(1)
                                                    Text(String(format: NSLocalizedString("S%d, E%d", comment: ""), item.episode.itemSeasonNumber, item.episode.itemEpisodeNumber))
                                                        .font(.caption)
                                                        .textCase(.uppercase)
                                                        .foregroundColor(.secondary)
                                                        .lineLimit(1)
                                                    Spacer()
                                                }
                                                Spacer()
                                            }
                                            .padding(.leading, item.id == viewModel.episodes.first?.id ? 16 : .zero)
                                            .padding(.trailing, item.id == viewModel.episodes.last?.id ? 16 : .zero)
                                            .frame(width: 140)
                                        }
                                    }
#endif
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
                        }
                        .onChange(of: shouldReload) { _, reload in
                            if reload {
                                if let firstItem = viewModel.episodes.first {
                                    withAnimation {
                                        proxy.scrollTo(firstItem.id, anchor: .topLeading)
                                    }
                                }
                                Task {
                                    await viewModel.reload(items)
                                    await MainActor.run {
                                        withAnimation(.easeInOut) {
                                            self.shouldReload = false
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .redacted(reason: viewModel.isLoaded ? [] : .placeholder)
            .navigationDestination(for: [UpNextEpisode].self) { _ in
                VerticalUpNextListView().environmentObject(viewModel)
            }
            .task(id: viewModel.isWatched) {
                if viewModel.isWatched {
                    await viewModel.handleWatched(selectedEpisode)
                    self.selectedEpisode = nil
                }
            }
            .task {
                await viewModel.load(items)
                await viewModel.checkForNewEpisodes(items)
            }
            .onChange(of: scene) { _, value in
                if scene == .active {
                    Task {
                        await viewModel.checkForNewEpisodes(items)
                    }
                }
            }
            .sheet(item: $selectedEpisode) { item in
                NavigationStack {
                    EpisodeDetailsView(episode: item.episode,
                                       season: item.episode.itemSeasonNumber,
                                       show: item.showID,
                                       showTitle: item.showTitle,
                                       isWatched: $viewModel.isWatched,
                                       isUpNext: true)
#if os(macOS) || os(iOS) || os(visionOS)
                    .nativeSheetDismissToolbar { self.selectedEpisode = nil }
#endif
                    .cronicaStandardNavigationDestinations()
                }
                .appTheme()
                .appTint()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
#if os(tvOS)
                .ignoresSafeArea()
#endif
#if os(macOS)
                .frame(minWidth: 800, idealWidth: 800, minHeight: 600, idealHeight: 600, alignment: .center)
#endif
            }
        }
    }
}

private struct UpNextCard: View {
    let item: UpNextEpisode
    @FocusState var isFocused
    @Binding var selectedEpisode: UpNextEpisode?
    @StateObject private var settings = SettingsStore.shared
    @EnvironmentObject var viewModel: UpNextViewModel
    @State private var showConfirmation = false
    var body: some View {
        VStack {
            Button {
                if settings.markEpisodeWatchedOnTap, settings.askConfirmationToMarkEpisodeWatched {
                    showConfirmation.toggle()
                } else if settings.markEpisodeWatchedOnTap, !settings.askConfirmationToMarkEpisodeWatched {
                    Task {
                        await viewModel.markAsWatched(item)
                    }
                } else {
                    selectedEpisode = item
                }
            } label: {
                ZStack {
                    LazyImage(url: settings.preferCoverOnUpNext ? item.backupImage : item.episode.itemImageLarge ?? item.backupImage) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            ZStack {
                                Rectangle().fill(.gray.gradient)
                                Image(systemName: "sparkles.tv")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(.white.opacity(0.8))
                                    .frame(width: 40, height: 40, alignment: .center)
                                    .padding()
                            }
                            .frame(width: settings.isCompactUI ? DrawingConstants.compactImageWidth : DrawingConstants.imageWidth,
                                   height: settings.isCompactUI ? DrawingConstants.compactImageHeight : DrawingConstants.imageHeight)
                            .clipShape(RoundedRectangle(cornerRadius: DrawingConstants.imageRadius, style: .continuous))
                        }
                    }
                    .transition(.opacity)
                    .frame(width: settings.isCompactUI ? DrawingConstants.compactImageWidth : DrawingConstants.imageWidth,
                           height: settings.isCompactUI ? DrawingConstants.compactImageHeight : DrawingConstants.imageHeight)
                    .clipShape(RoundedRectangle(cornerRadius: DrawingConstants.imageRadius,
                                                style: .continuous))
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
                    .applyHoverEffect()
#if !os(tvOS)
                    if !settings.isCompactUI {
                        VStack(alignment: .leading) {
                            Spacer()
                            ZStack(alignment: .bottom) {
                                Color.black.opacity(0.4)
                                    .frame(height: 50)
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
                                    .fill(.ultraThinMaterial)
                                    .frame(height: 70)
                                    .mask {
                                        VStack(spacing: 0) {
                                            LinearGradient(colors: [Color.black.opacity(0),
                                                                    Color.black.opacity(0.383),
                                                                    Color.black.opacity(0.707),
                                                                    Color.black.opacity(0.924),
                                                                    Color.black],
                                                           startPoint: .top,
                                                           endPoint: .bottom)
                                            .frame(height: 50)
                                            Rectangle()
                                        }
                                    }
                                
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(item.showTitle)
                                            .font(.callout)
                                            .foregroundColor(.white)
                                            .fontWeight(.semibold)
                                            .lineLimit(1)
                                        Text(String(format: NSLocalizedString("S%d, E%d", comment: ""), item.episode.itemSeasonNumber, item.episode.itemEpisodeNumber))
                                            .font(.caption)
                                            .textCase(.uppercase)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white.opacity(0.8))
                                            .lineLimit(1)
                                    }
                                    .padding(.bottom, 8)
                                    Spacer()
                                }
                                .padding(.bottom, 8)
                                .padding(.leading)
                            }
                        }
                    }
#endif
                }
            }
            .contextMenu {
                Button("Show Details") {
                    selectedEpisode = item
                }
                Button("Skip this episode") {
                    Task { await viewModel.skipEpisode(for: item) }
                }
            }
#if os(tvOS)
            .buttonStyle(.card)
            .focused($isFocused)
#endif
            
#if os(tvOS)
            HStack {
                Text(item.showTitle)
                    .font(.caption)
                    .lineLimit(2)
                    .accessibilityHidden(true)
                    .foregroundColor(isFocused ? .primary : .secondary)
                Spacer()
            }
            .frame(width: DrawingConstants.imageWidth)
            HStack {
                Text(String(format: NSLocalizedString("S%d, E%d", comment: ""), item.episode.itemSeasonNumber, item.episode.itemEpisodeNumber))
                    .font(.caption)
                    .textCase(.uppercase)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                Spacer()
            }
            Spacer()
#endif
        }
        .padding(.top)
        .confirmationDialog("Confirm Watched Episode",
                            isPresented: $showConfirmation, titleVisibility: .visible) {
            Button("Confirm") {
                Task {
                    await viewModel.markAsWatched(item)
                }
            }
            Button("Cancel", role: .cancel) {
                showConfirmation = false
            }
        } message: {
            Text("Mark Episode \(item.episode.itemEpisodeNumber) from season \(item.episode.itemSeasonNumber) of \(item.showTitle) as Watched?")
        }
        .contextMenu {
            Button("Details") {
                selectedEpisode = item
            }
        }
    }
}

private struct DrawingConstants {
#if !os(tvOS)
    static let imageWidth: CGFloat = 280
    static let imageHeight: CGFloat = 160
#else
    static let imageWidth: CGFloat = 420
    static let imageHeight: CGFloat = 240
#endif
    static let compactImageWidth: CGFloat = 160
    static let compactImageHeight: CGFloat = 100
    static let imageRadius: CGFloat = 12
    static let titleLineLimit: Int = 1
    static let imageShadow: CGFloat = 2.5
}
