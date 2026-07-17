//
//  SeasonDetailView.swift
//  Story (iOS)
//
//  Created by Alexandre Madeira on 11/04/24.
//

import SwiftUI
import NukeUI

struct SeasonDetailView: View {
    @StateObject private var settings: SettingsStore = .shared
    var item: Season
    var showID: Int
    @Binding var selectedSeasonDetails: Season?
    var body: some View {
        NavigationStack {
            Form {
                // header section for the season details
                Section {
                    VStack(alignment: .center) {
                        HStack(alignment: .center) {
                            LazyImage(url: item.seasonPosterUrl) { state in
                                if let image = state.image {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } else {
                                    ZStack {
                                        Rectangle().fill(.gray.gradient)
                                        Image(systemName: "tv")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 50, height: 50, alignment: .center)
                                            .foregroundColor(.white)
                                    }
                                }
                            }
#if !os(tvOS)
                            .frame(width: 150, height: 220)
#else
                            .frame(width: 338, height: 525)
#endif
                            .clipShape(RoundedRectangle(cornerRadius: CronicaDesign.Radius.media, style: .continuous))
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 10)
                        }
                        .frame(maxWidth: .infinity)
                        
                        if let name = item.name {
                            Text(name)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                                .font(.title3)
                        } else {
                            Text("Season \(item.seasonNumber)")
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                                .font(.title3)
                        }
                        
                        if let release = item.itemDate {
                            Text("Premiered on \(release)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        if let episodesCount = item.episodes?.count {
                            Text("Season \(item.seasonNumber)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(episodesCount) episodes")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        if let overview = item.overview {
                            Text(overview)
                                .font(.callout)
                                .padding(.vertical)
#if os(macOS)
                                .padding(.horizontal)
#endif
                        }
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .padding(.top, .zero)
            }
#if !os(tvOS) && !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
#if !os(tvOS) && !os(visionOS)
            .scrollContentBackground(settings.disableTranslucent ? .visible : .hidden)
            .background {
                TranslucentBackground(image: item.seasonPosterUrl, useLighterMaterial: true)
            }
#endif
            .scrollBounceBehavior(.basedOnSize)
            .toolbar {
#if os(macOS)
                ToolbarItem {
                    Button("Close") {
                        selectedSeasonDetails = nil
                    }
                }
#else
                ToolbarItem(placement: .topBarLeading) {
                    RoundedCloseButton {
                        selectedSeasonDetails = nil
                    }
                }
#endif
#if !os(tvOS) && !os(macOS)
                ToolbarItem(placement: .topBarTrailing) {
                    if let url = URL(string: "https://www.themoviedb.org/tv/\(showID)/season/\(item.seasonNumber)") {
                        ShareLink(item: url) {
                            Image(systemName: "square.and.arrow.up")
                                .imageScale(.medium)
                                .accessibilityLabel("Share")
                                .fontDesign(.rounded)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                        }
                        .buttonStyle(.borderedProminent)
                        .contentShape(Circle())
                        .clipShape(Circle())
                        .buttonBorderShape(.circle)
                        .shadow(radius: 2.5)
                    }
                }
#endif
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(CronicaDesign.Radius.media)
#if os(macOS)
        .frame(width: 600, height: 400)
#endif
    }
}
