//
//  VerticalUpNextCardView.swift
//  Story (iOS)
//
//  Created by Alexandre Madeira on 05/02/24.
//

import SwiftUI
import NukeUI

struct VerticalUpNextCardView: View {
    let item: UpNextEpisode
    @StateObject private var settings: SettingsStore = .shared
    @State private var askConfirmation = false
    @EnvironmentObject var viewModel: UpNextViewModel
    @Binding var selectedEpisode: UpNextEpisode?
    var body: some View {
        Button {
            if settings.markEpisodeWatchedOnTap, settings.askConfirmationToMarkEpisodeWatched {
                askConfirmation.toggle()
            } else if settings.markEpisodeWatchedOnTap, !settings.askConfirmationToMarkEpisodeWatched {
                Task {
                    await viewModel.markAsWatched(item)
                }
            } else {
                selectedEpisode = item
            }
        } label: {
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
                    .frame(width: DrawingConstants.imageWidth,
                           height: DrawingConstants.imageHeight)
                }
            }
            .frame(width: DrawingConstants.imageWidth,
                   height: DrawingConstants.imageHeight)
            .transition(.opacity)
            .clipShape(RoundedRectangle(cornerRadius: DrawingConstants.imageRadius, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Show Details") {
                selectedEpisode = item
            }
            Button("Skip this episode") {
                Task { await viewModel.skipEpisode(for: item) }
            }
            Button("Hide from Up Next", systemImage: "eye.slash") {
                Task { await viewModel.hideFromUpNext(item) }
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
}
