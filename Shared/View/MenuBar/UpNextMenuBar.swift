//
//  UpNextMenuBar.swift
//  Story (iOS)
//
//  Created by Alexandre Madeira on 22/11/23.
//

import SwiftUI
import NukeUI

struct UpNextMenuBar: View {
    @StateObject private var viewModel: UpNextViewModel = .shared
    @StateObject private var settings = SettingsStore.shared
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WatchlistItem.title, ascending: true)],
        predicate: NSCompoundPredicate(type: .and, subpredicates: [ NSPredicate(format: "displayOnUpNext == %d", true),
                                                                    NSPredicate(format: "isArchive == %d", false),
                                                                    NSPredicate(format: "watched == %d", false)]),
        animation: .default
    ) private var items: FetchedResults<WatchlistItem>
    var body: some View {
        Form {
            Section {
                List {
                    ForEach(viewModel.episodes) { item in
                        Button {
                            Task { await viewModel.markAsWatched(item) }
                        } label: {
                            upNextRowItem(item)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, item == viewModel.episodes.first ? 8 : 0)
                        .padding(.top, item == viewModel.episodes.last ? 8 : 0)
                    }
                }
                .cronicaLoadingOverlay(!viewModel.isLoaded)
                .redacted(reason: viewModel.isLoaded ? [] : .placeholder)
            } header: {
                HStack {
                    Text("Up Next")
                        .font(.callout)
                        .fontWeight(.semibold)
                    Spacer()
                    Button("Refresh", systemImage: "arrow.clockwise") {
                        Task { await viewModel.reload(items) }
                    }
                    .labelStyle(.iconOnly)
                }
                
            }
        }
        .task {
            await viewModel.load(items)
            await viewModel.checkForNewEpisodes(items)
        }
        .onChange(of: settings.upNextSortOrder) { _, _ in
            Task { await viewModel.reload(items) }
        }
        .onChange(of: settings.hideUnstartedUpNext) { _, _ in
            Task { await viewModel.reload(items) }
        }
#if os(macOS)
        .formStyle(.grouped)
#endif
    }
    
    private func upNextRowItem(_ item: UpNextEpisode) -> some View {
        HStack {
            LazyImage(url: item.episode.itemImageSmall ?? item.backupImage) { state in
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
                    .frame(width: 95, height: 50)
                }
            }
            .transition(.opacity)
            .frame(width: 95, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading) {
                Text(item.showTitle)
                    .font(.callout)
                    .lineLimit(1)
                Text(String(format: String(localized: "S%d, E%d"), item.episode.itemSeasonNumber, item.episode.itemEpisodeNumber))
                    .font(.caption)
                    .textCase(.uppercase)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                if settings.upNextSortOrder == .watchProgress, let progress = item.watchProgressLabel {
                    Text(progress)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.leading, 2)
            Spacer()
        }
    }
}
