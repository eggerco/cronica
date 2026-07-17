//
//  EpisodeView.swift
//  Cronica Watch App
//
//  Created by Alexandre Madeira on 27/09/22.
//

import SwiftUI
import NukeUI

struct EpisodeRow: View {
    let episode: Episode
    let season: Int
    let show: Int
    private let persistence = PersistenceController.shared
    @State private var isWatched: Bool = false
    var body: some View {
        HStack(spacing: CronicaDesign.Spacing.sm) {
            LazyImage(url: episode.itemImageMedium) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    ZStack {
                        Rectangle().fill(.secondary)
                        Image(systemName: "tv")
                    }
                    .frame(width: DrawingConstants.imageWidth,
                           height: DrawingConstants.imageHeight)
                }
            }
            .transition(.opacity)
            .frame(width: DrawingConstants.imageWidth,
                   height: DrawingConstants.imageHeight)
            .clipShape(
                RoundedRectangle(cornerRadius: CronicaDesign.Radius.media,
                                 style: .continuous)
            )
            .overlay {
                if isWatched {
                    ZStack {
                        Color.black.opacity(0.6)
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.white)
                    }
                    .clipShape(
                        RoundedRectangle(cornerRadius: CronicaDesign.Radius.media,
                                         style: .continuous)
                    )
                    .frame(width: DrawingConstants.imageWidth,
                           height: DrawingConstants.imageHeight)
                }
            }
            VStack(alignment: .leading, spacing: CronicaDesign.Spacing.xxs) {
                Text(episode.itemTitle)
                    .lineLimit(DrawingConstants.lineLimit)
                    .font(CronicaDesign.Typography.caption())
                Text("E\(episode.itemEpisodeNumberDisplay)")
                    .font(CronicaDesign.Typography.caption())
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.horizontal, CronicaDesign.Spacing.sm)
        .accessibilityElement(children: .combine)
        .task {
            isWatched = persistence.isEpisodeSaved(show: show, season: season, episode: episode.id)
        }
    }
}

private struct DrawingConstants {
    static let imageWidth: CGFloat = 70
    static let imageHeight: CGFloat = 45
    static let lineLimit: Int = 1
}
