//
//  EpisodeDetailsView.swift
//  Cronica Watch App
//
//  Created by Alexandre Madeira on 27/09/22.
//

import SwiftUI

struct EpisodeDetailsView: View {
    let episode: Episode
    let season: Int
    let show: Int
    var showTitle = String()
    @Binding var isWatched: Bool
    private let persistence = PersistenceController.shared
    @StateObject private var settings = SettingsStore.shared
    var body: some View {
        ScrollView {
            VStack(spacing: CronicaDesign.Spacing.sm) {
                HeroImage(url: episode.itemImageMedium,
                          title: episode.itemTitle)

                VStack(spacing: CronicaDesign.Spacing.xxs) {
                    Text(showTitle)
                        .padding(.horizontal, CronicaDesign.Spacing.sm)
                        .font(CronicaDesign.Typography.display())
                        .lineLimit(2)
                        .multilineTextAlignment(.center)

                    Text(episode.itemTitle)
                        .padding(.horizontal, CronicaDesign.Spacing.sm)
                        .font(CronicaDesign.Typography.caption())
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, CronicaDesign.Spacing.xs)

                Text(String(format: NSLocalizedString("S%d, E%d", comment: ""), episode.itemSeasonNumber, episode.itemEpisodeNumber))
                    .font(CronicaDesign.Typography.caption())
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, CronicaDesign.Spacing.sm)
                    .padding(.bottom, CronicaDesign.Spacing.xs)

                WatchEpisodeButton(episode: episode, season: season, show: show, isWatched: $isWatched)
                    .buttonStyle(.borderedProminent)
                    .tint(isWatched ? settings.appTheme.color.opacity(0.75) : settings.appTheme.color)
                    .padding(.bottom, CronicaDesign.Spacing.xs)
                    .padding(.horizontal, CronicaDesign.Spacing.sm)
                    .onAppear(perform: load)

                if let url = URL(string: "https://www.themoviedb.org/tv/\(show)/season/\(season)/episode/\(episode.itemEpisodeNumberDisplay)") {
                    ShareLink(item: url)
                        .labelStyle(.iconOnly)
                        .padding(.horizontal, CronicaDesign.Spacing.sm)
                        .padding(.bottom, CronicaDesign.Spacing.sm)
                }

                AboutSectionView(about: episode.itemOverview)
                    .padding(.horizontal, CronicaDesign.Spacing.sm)
                    .padding(.bottom, CronicaDesign.Spacing.sm)
            }
        }
        .background {
            TranslucentBackground(image: episode.itemImageMedium)
        }
    }

    private func load() {
        isWatched = persistence.isEpisodeSaved(show: show,
                                                 season: season,
                                                 episode: episode.id)
    }
}
