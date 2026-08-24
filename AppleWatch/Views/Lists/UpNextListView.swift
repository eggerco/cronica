//
//  UpNextListView.swift
//  Cronica Watch App
//
//  Created by Alexandre Madeira on 17/07/23.
//

import SwiftUI
import NukeUI

struct UpNextListView: View {
    static let tag: Screens? = .upNext
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
        NavigationStack {
            VStack {
                if items.isEmpty {
                    ContentUnavailableView("Your episodes will appear here.",
                                           systemImage: "tv")
                } else {
                    List {
                        ForEach(viewModel.episodes) { episode in
                            UpNextRowItemView(item: episode)
                                .environmentObject(viewModel)
                        }
                        Button {
                            Task {
                                await viewModel.reload(items)
                            }
                        } label: {
                            CenterHorizontalView {
                                Text("Reload")
                            }
                        }
                    }
                    .overlay { if !viewModel.isLoaded { CronicaLoadingPopupView() } }
                    .redacted(reason: viewModel.isLoaded ? [] : .placeholder)
                    .task {
                        await viewModel.load(items)
                        await viewModel.checkForNewEpisodes(items)
                    }
                    .refreshable {
                        Task { await viewModel.reload(items) }
                    }
                    
                }
            }
            .navigationTitle("Up Next")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: scene) { _, _ in
                if scene == .active {
                    Task {
                        await viewModel.checkForNewEpisodes(items)
                    }
                }
            }
        }
    }
}

private struct DrawingConstants {
    static let imageWidth: CGFloat = 70
    static let imageHeight: CGFloat = 50
    static let imageRadius: CGFloat = 12
    static let textLimit: Int = 1
}

#Preview {
    UpNextListView()
}

private struct UpNextRowItemView: View {
    let item: UpNextEpisode
    @State private var askConfirmation = false
    @EnvironmentObject var viewModel: UpNextViewModel
    var body: some View {
        Button {
            askConfirmation.toggle()
        } label: {
            HStack {
                LazyImage(url: item.episode.itemImageMedium ?? item.backupImage) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        ZStack {
                            Rectangle().fill(.gray.gradient)
                            Image(systemName: "sparkles.tv")
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .unredacted()
                        .frame(width: DrawingConstants.imageWidth,
                               height: DrawingConstants.imageHeight)
                    }
                }
                .transition(.opacity)
                .frame(width: DrawingConstants.imageWidth,
                       height: DrawingConstants.imageHeight)
                .clipShape(RoundedRectangle(cornerRadius: DrawingConstants.imageRadius, style: .continuous))
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
                .padding(.leading, 2)
                Spacer()
            }
        }
        .confirmationDialog("Confirm Watched Episode",
                            isPresented: $askConfirmation, titleVisibility: .visible) {
            Button("Confirm") {
                Task {
                    await viewModel.markAsWatched(item)
                }
            }
            Button("Cancel", role: .cancel) {
                askConfirmation = false
            }
        } message: {
            Text("Mark Episode \(item.episode.itemEpisodeNumber) from season \(item.episode.itemSeasonNumber) of \(item.showTitle) as Watched?")
        }
        
    }
}
