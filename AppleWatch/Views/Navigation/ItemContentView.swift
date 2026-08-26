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
    var body: some View {
        VStack {
            ScrollView {
                HeroImage(url: image, title: title)
				
				if let quickInfo = viewModel.content?.itemQuickInfo {
					Text(type.title)
						.font(.caption)
						.multilineTextAlignment(.center)
						.padding(.horizontal)
						.foregroundColor(.secondary)
					Text(quickInfo)
						.font(.caption)
						.multilineTextAlignment(.center)
						.padding(.horizontal)
						.foregroundColor(.secondary)
				}
                
                Button {
                    if viewModel.isInWatchlist {
                        if SettingsStore.shared.showRemoveConfirmation {
                            showConfirmationPopup = true
                        } else {
                            updateWatchlist()
                        }
                    } else {
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
                            .font(.caption)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(viewModel.isLoading)
                .confirmationDialog("Are You Sure?",
                                    isPresented: $showConfirmationPopup,
                                    titleVisibility: .visible) {
                    Button("Confirm") { updateWatchlist() }
                    Button("Cancel") {  showConfirmationPopup = false }
                }
                .padding()
                
                if let seasons = viewModel.content?.seasons {
                    NavigationLink("Seasons", value: seasons)
                        .padding([.horizontal, .bottom])
                }
                
                HStack {
                    if viewModel.isInWatchlist {
                        //customListButton
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
                                    pinButton.padding(.bottom)
                                    favoriteButton.padding(.bottom)
                                    watchButton.padding(.bottom)
                                    archiveButton.padding(.bottom)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding([.bottom, .horizontal])
                
                AboutSectionView(about: viewModel.content?.itemOverview)
                
                shareButton
                
                AttributionView()
            }
        }
        .task { await viewModel.load(id: id, type: type) }
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
                    .font(.caption)
                    .lineLimit(1)
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.bordered)
    }
    
    private var customListButton: some View {
        Button("Add To List", systemImage: "rectangle.on.rectangle.angled") {
            showCustomListSheet.toggle()
        }
        .labelStyle(.iconOnly)
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
                    .font(.caption)
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
                    .font(.caption)
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
                    .font(.caption)
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
		case .cronica: if let cronicaUrl {
			ShareLink(item: cronicaUrl, subject: Text(viewModel.content?.itemTitle ?? title), message: Text(viewModel.content?.itemTitle ?? title))
		}
		}
	}
	
	private var cronicaUrl: URL? {
		guard let item = viewModel.content else { return nil }
		return AppWebsite.detailsURL(
			contentID: item.itemContentID,
			posterPath: item.posterPath,
			title: item.itemTitle
		)
	}
    
    private func updateWatchlist() {
        guard let item = viewModel.content else { return }
        viewModel.updateWatchlist(with: item)
        if settings.openListSelectorOnAdding && viewModel.isInWatchlist {
            showCustomListSheet.toggle()
        }
    }
}

private struct DrawingConstants {
    static let imageRadius: CGFloat = 12
    static let lineLimit: Int = 1
}

#Preview {
    ItemContentView(id: ItemContent.example.id,
                    title: ItemContent.example.itemTitle,
                    type: ItemContent.example.itemContentMedia,
                    image: ItemContent.example.cardImageMedium)
}
