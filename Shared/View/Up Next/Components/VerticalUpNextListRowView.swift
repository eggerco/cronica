//
//  VerticalUpNextListRowView.swift
//  Story (iOS)
//
//  Created by Alexandre Madeira on 05/02/24.
//

import SwiftUI
import NukeUI

struct VerticalUpNextListRowView: View {
    let item: UpNextEpisode
    @StateObject private var settings: SettingsStore = .shared
    @State private var askConfirmation = false
    @EnvironmentObject var viewModel: UpNextViewModel
    @Binding var selectedEpisode: UpNextEpisode?
    var body: some View {
        Button {
            askConfirmation.toggle()
        } label: {
            HStack {
                LazyImage(url: settings.preferCoverOnUpNext ? item.backupImage : item.episode.itemImageLarge ?? item.backupImage) { state in
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
                        .frame(width: 80, height: 50)
                    }
                }
                .transition(.opacity)
                .frame(width: 80, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                VStack(alignment: .leading) {
                    Text(item.showTitle)
                        .font(.callout)
                        .lineLimit(1)
                    Text(String(format: NSLocalizedString("S%d, E%d", comment: ""), item.episode.itemSeasonNumber, item.episode.itemEpisodeNumber))
                        .font(.caption)
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
        .buttonStyle(.plain)
#if !os(tvOS)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button("Watched", systemImage: "rectangle.badge.checkmark") {
                Task { await viewModel.markAsWatched(item) }
            }
        }
#endif
        .contextMenu {
            Button("Show Details") {
                selectedEpisode = item
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
