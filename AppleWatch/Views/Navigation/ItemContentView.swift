//
//  ItemContentView.swift
//  Cronica Watch App
//
//  Created by Alexandre Madeira on 03/08/22.
//

import SwiftUI
import NukeUI

struct ItemContentView: View {
    let id: Int
    let title: String
	let type: MediaType
    let image: URL?
    @StateObject private var viewModel = ItemContentViewModel()
    @State private var showCustomListSheet = false
    @State private var showMoreOptions = false
    @State private var isWatched = false
	@StateObject private var store = SettingsStore.shared
    @State private var showConfirmationPopup = false
    @StateObject private var settings = SettingsStore.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    var body: some View {
        VStack {
            ScrollView {
                HeroImage(url: image, title: title)
                    .opacity(appeared ? 1 : 0)

                Text(title)
                    .font(CronicaDesign.Typography.display())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, CronicaDesign.Spacing.sm)
                    .opacity(appeared ? 1 : 0)

				if let quickInfo = viewModel.content?.itemQuickInfo {
					Text(type.title)
                        .font(CronicaDesign.Typography.caption())
						.multilineTextAlignment(.center)
                        .padding(.horizontal, CronicaDesign.Spacing.sm)
						.foregroundStyle(.secondary)
					Text(quickInfo)
                        .font(CronicaDesign.Typography.caption())
						.multilineTextAlignment(.center)
                        .padding(.horizontal, CronicaDesign.Spacing.sm)
						.foregroundStyle(.secondary)
				}
                
                Button {
                    if viewModel.isInWatchlist {
                        if SettingsStore.shared.showRemoveConfirmation {
                            showConfirmationPopup = true
                        } else {
                            updateWatchlist()
                        }
                    } else {
                        HapticManager.shared.successHaptic()
                        updateWatchlist()
                    }
                } label: {
                    HStack {
                        Image(systemName: viewModel.isInWatchlist ? "minus.circle.fill" : "plus.circle.fill")
                            .symbolEffect(viewModel.isInWatchlist ? .bounce.down : .bounce.up,
                                          value: viewModel.isInWatchlist)
                            .imageScale(.medium)
                        Text(viewModel.isInWatchlist ? "Remove" : "Add")
                            .lineLimit(1)
                            .padding(.top, 2)
                            .font(CronicaDesign.Typography.caption())
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(viewModel.isInWatchlist ? .red.opacity(0.9) : settings.appTheme.color)
                .controlSize(.small)
                .disabled(viewModel.isLoading)
                .confirmationDialog("Are You Sure?",
                                    isPresented: $showConfirmationPopup,
                                    titleVisibility: .visible) {
                    Button("Confirm") { updateWatchlist() }
                    Button("Cancel") {  showConfirmationPopup = false }
                }
                .padding(.vertical, CronicaDesign.Spacing.xs)
                
                if let seasons = viewModel.content?.seasons {
                    NavigationLink("Seasons", value: seasons)
                        .padding([.horizontal, .bottom], CronicaDesign.Spacing.sm)
                }
                
                HStack {
                    if viewModel.isInWatchlist {
                        Button {
                            showMoreOptions.toggle()
                        } label: {
                            Label("More", systemImage: "ellipsis")
                                .labelStyle(.iconOnly)
                        }
                        .disabled(viewModel.isLoading)
                        .sheet(isPresented: $showMoreOptions) {
                            VStack {
                                ScrollView {
                                    pinButton.padding(.bottom, CronicaDesign.Spacing.xs)
                                    favoriteButton.padding(.bottom, CronicaDesign.Spacing.xs)
                                    watchButton.padding(.bottom, CronicaDesign.Spacing.xs)
                                    archiveButton.padding(.bottom, CronicaDesign.Spacing.xs)
                                }
                                .padding(.horizontal, CronicaDesign.Spacing.sm)
                            }
                        }
                    }
                }
                .padding([.bottom, .horizontal], CronicaDesign.Spacing.sm)
                
                AboutSectionView(about: viewModel.content?.itemOverview)
                
                shareButton
                
                AttributionView()
            }
        }
        .task { await viewModel.load(id: id, type: type) }
        .onAppear {
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(CronicaDesign.Motion.standard) {
                    appeared = true
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .redacted(reason: viewModel.isLoading ? .placeholder : [])
        .sheet(isPresented: $showCustomListSheet) {
            if let contentID = viewModel.content?.itemContentID {
                ItemContentCustomListSelector(contentID: contentID,
                                              showView: $showCustomListSheet,
                                              title: title,
                                              image: viewModel.content?.posterImageMedium)
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
            }
        }
        .navigationDestination(for: [Season].self) { seasons in
            if let season = viewModel.content?.seasons {
                SeasonListView(
                    showID: id,
                    showTitle: title,
                    seasons: season,
                    isInWatchlist: $viewModel.isInWatchlist,
                    showCover: viewModel.content?.cardImageMedium
                )
            }
        }
        .navigationDestination(for: [Int:Episode].self) { item in
            let keys = item.map { (key, _) in key }.first
            let value = item.map { (_, value) in value }.first
            if let keys, let value {
                EpisodeDetailsView(episode: value, season: keys, show: id, showTitle: title, isWatched: $isWatched)
            }
        }
        .background { TranslucentBackground(image: image) }
    }
    
    private var watchButton: some View {
        Button {
            viewModel.update(.watched)
        } label: {
            HStack {
                Image(systemName: viewModel.isWatched ? "rectangle.badge.checkmark.fill" : "rectangle.badge.checkmark")
                    .symbolEffect(viewModel.isWatched ? .bounce.down : .bounce.up,
                                  value: viewModel.isWatched)
                    .imageScale(.medium)
                Text("Watched")
                    .padding(.top, 2)
                    .font(CronicaDesign.Typography.caption())
                    .lineLimit(1)
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.bordered)
    }
    
    private var favoriteButton: some View {
        Button {
            viewModel.update(.favorite)
        } label: {
            HStack {
                Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                    .symbolEffect(viewModel.isFavorite ? .bounce.down : .bounce.up,
                                  value: viewModel.isFavorite)
                    .imageScale(.medium)
                Text("Favorite")
                    .padding(.top, 2)
                    .font(CronicaDesign.Typography.caption())
                    .lineLimit(1)
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.bordered)
    }
    
    private var archiveButton: some View {
        Button {
            viewModel.update(.archive)
        } label: {
            HStack {
                Image(systemName: viewModel.isArchive ? "archivebox.fill" : "archivebox")
                    .symbolEffect(viewModel.isArchive ? .bounce.down : .bounce.up,
                                  value: viewModel.isArchive)
                    .imageScale(.medium)
                Text("Archive")
                    .padding(.top, 2)
                    .font(CronicaDesign.Typography.caption())
                    .lineLimit(1)
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.bordered)
    }
    
    private var pinButton: some View {
        Button {
            viewModel.update(.pin)
        } label: {
            HStack {
                Image(systemName: viewModel.isPin ? "pin.fill" : "pin")
                    .symbolEffect(viewModel.isPin ? .bounce.down : .bounce.up,
                                  value: viewModel.isPin)
                    .imageScale(.medium)
                Text("Pin")
                    .padding(.top, 2)
                    .font(CronicaDesign.Typography.caption())
                    .lineLimit(1)
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.bordered)
    }
	
	@ViewBuilder
	private var shareButton: some View {
		switch store.shareLinkPreference {
		case .tmdb: if let url = viewModel.content?.itemURL { ShareLink(item: url) }
		case .cronica: if let cronicaUrl { ShareLink(item: cronicaUrl) }
		}
	}
	
	private var cronicaUrl: URL? {
		if let item = viewModel.content {
			let encodedTitle = item.itemTitle.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
			let posterPath = item.posterPath ?? String()
			let encodedPoster = posterPath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
			return URL(string: "https://www.oncronica.com/details?id=\(item.itemContentID)&img=\(encodedPoster ?? String())&title=\(encodedTitle ?? String())")
		}
		return nil
	}
    
    private func updateWatchlist() {
        guard let item = viewModel.content else { return }
        viewModel.updateWatchlist(with: item)
        if settings.openListSelectorOnAdding && viewModel.isInWatchlist {
            showCustomListSheet.toggle()
        }
    }
}

#Preview {
    ItemContentView(id: ItemContent.example.id,
                    title: ItemContent.example.itemTitle,
                    type: ItemContent.example.itemContentMedia,
                    image: ItemContent.example.cardImageMedium)
}
