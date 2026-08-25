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
    var body: some View {
        ScrollView {
            VStack {
                HeroImage(url: episode.itemImageMedium,
                          title: episode.itemTitle)
                .clipShape(
                    RoundedRectangle(cornerRadius: DrawingConstants.imageRadius,
                                     style: .continuous)
                )
                .padding()
                
				VStack {
					Text(showTitle)
						.padding(.horizontal)
						.font(.callout)
						.fontWeight(.semibold)
						.lineLimit(2)
						.multilineTextAlignment(.center)
					
					Text(episode.itemTitle)
						.padding(.horizontal)
						.font(.caption)
						.lineLimit(2)
						.multilineTextAlignment(.center)
						.foregroundStyle(.secondary)
				}.padding(.horizontal)
                   
                
				Text(String(format: String(localized: "S%d, E%d"), episode.itemSeasonNumber, episode.itemEpisodeNumber))
                    .font(.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding([.horizontal, .bottom])
                
                WatchEpisodeButton(episode: episode, season: season, show: show, isWatched: $isWatched)
                    .buttonStyle(.borderedProminent)
                    .tint(isWatched ? .orange : .green)
                    .padding([.bottom, .horizontal])
                    .onAppear(perform: load)
                
                if let url = URL(string: "https://www.themoviedb.org/tv/\(show)/season/\(season)/episode/\(episode.itemEpisodeNumberDisplay)") {
                    ShareLink(item: url)
                        .labelStyle(.iconOnly)
						.padding(.horizontal)
                        .padding([.bottom, .horizontal])
                }
                
                AboutSectionView(about: episode.itemOverview)
					.padding([.horizontal, .bottom])
                
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

private struct DrawingConstants {
    static let imageRadius: CGFloat = 12
    static let imageWidth: CGFloat = 324
    static let imageHeight: CGFloat = 163
    static let lineLimit: Int = 1
}
