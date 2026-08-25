//
//  ItemContentDetails.swift
//  Cronica
//
//  Created by Alexandre Madeira on 02/03/22.
//

import SwiftUI
import NukeUI
#if !os(tvOS)
import Pow
#endif

struct ItemContentDetails: View {
    var title: String
    var id: Int
    var type: MediaType
    @StateObject private var viewModel = ItemContentViewModel()
    @StateObject private var store = SettingsStore.shared
    @State private var showPopup = false
    @State private var showSeasonConfirmation = false
    @State private var switchMarkAsView = false
    @State private var showCustomList = false
    @State private var showUserNotes = false
    @State private var popupType: ActionPopupItems?
    @State private var showReleaseDateInfo = false
    @State private var animateGesture = false
    @State private var animationImage = ""
    @State private var showConfirmationPopup = false
    @State private var showUnwatchConfirmation = false
    @State private var showNotReleasedAlert = false
    
    // MARK: View properties for sizeBasedPadMacView
    @State private var isSideInfoPanelShowed = false
    @State private var showInfoBox = false
    @State private var showOverview = false
    var handleToolbar = false
    
    // MARK: View properties for sizeBasedTVView
    @State private var hasFocused = false
    @FocusState var isWatchlistInFocus: Bool
    @FocusState var isWatchInFocus: Bool
    @FocusState var isFavoriteInFocus: Bool
    @FocusState var isMoreInFocus: Bool
    @Namespace var tvOSActionNamespace
    @FocusState var isWatchlistButtonFocused: Bool
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.openURL) private var openURL
    
    // MARK: Animation properties
    @State private var animateFavorite = false
    var body: some View {
        ScrollView {
            VStack {
#if os(macOS) || os(visionOS)
                sizeBasedPadMacView
#elseif os(iOS)
                if horizontalSizeClass == .regular {
                    sizeBasedPadMacView
                } else {
                    sizedBasedPhoneView
                }
#elseif os(tvOS)
                sizeBasedTVView
#endif
            }
        }
        .accessibilityIdentifier("Item Content Details View")
#if !os(tvOS)
        .toolbar {
#if os(iOS)
            if horizontalSizeClass == .regular {
                ToolbarItem {
                    HStack {
                        if viewModel.isInWatchlist {
                            if type == .movie {
                                favoriteButtonToolbar
                            } else {
                                watchButtonToolbar
                            }
                            archiveButtonToolbar
                            pinButtonToolbar
                            reviewButtonToolbar
                        }
                        shareButton
                        moreMenu
                    }
                }
            } else {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        shareButton
                        moreMenu
                    }
                    .unredacted()
                }
            }
#else
            if handleToolbar {
                ToolbarItem(placement: .status) { toolbarRow }
            } else {
                ToolbarItem { toolbarRow }
            }
#endif
        }
#endif
        .redacted(reason: viewModel.isLoading ? .placeholder : [])
        .cronicaLoadingOverlay(viewModel.isLoading)
#if !os(visionOS)
        .background {
            TranslucentBackground(image: viewModel.showPoster ? viewModel.content?.posterImageMedium : viewModel.content?.cardImageLarge)
        }
#endif
        .task {
            await viewModel.load(id: id, type: type)
            viewModel.registerNotification()
            viewModel.checkIfAdded()
        }
        .actionPopup(isShowing: $showPopup, for: popupType)
        .cronicaErrorAlert(isPresented: $viewModel.showErrorAlert, message: viewModel.errorMessage) {
            Task { await viewModel.load(id: id, type: type) }
        }
        .confirmationDialog("Reset Episode Progress?",
                            isPresented: $showUnwatchConfirmation,
                            titleVisibility: .visible) {
            Button("Reset Progress", role: .destructive) {
                viewModel.updateWatched(resetEpisodeProgress: true)
                resetPopupAnimation()
                animatePopup(for: .removedWatched)
            }
            Button("Keep Progress") {
                viewModel.updateWatched(resetEpisodeProgress: false)
                resetPopupAnimation()
                animatePopup(for: .removedWatched)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Marking this series as unwatched can clear watched episodes. Choose whether to reset progress or keep it.")
        }
        .alert("Not Released Yet", isPresented: $showNotReleasedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You can mark this as watched after it has been released.")
        }
        .sheet(isPresented: $showCustomList) {
            if let contentID = viewModel.content?.itemContentID {
                ItemContentCustomListSelector(contentID: contentID,
                                              showView: $showCustomList,
                                              title: title, image: viewModel.content?.posterImageMedium)
                .onDisappear {
                    viewModel.checkListStatus()
                }
            }
        }
        .sheet(isPresented: $showUserNotes, onDismiss: {
            viewModel.refreshWatchedDate()
        }) {
            if let contentID = viewModel.content?.itemContentID {
                ReviewView(id: contentID, showView: $showUserNotes)
            }
        }
        .sheet(isPresented: $showReleaseDateInfo) {
            let productionRegion = viewModel.content?.productionCountries?.first?.iso31661 ?? "US"
            DetailedReleaseDateView(item: viewModel.content?.releaseDates?.results,
                                    productionRegion: productionRegion,
                                    dismiss: $showReleaseDateInfo)
        }
#if os(tvOS)
        .ignoresSafeArea(.all, edges: .horizontal)
#endif
    }
    
#if os(iOS)
    private var sizedBasedPhoneView: some View {
        VStack {
            if viewModel.showPoster || store.usePostersAsCover {
                poster
            } else {
                cover
            }
            
            Text(title)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .font(.title2)
                .fontDesign(.rounded)
                .fontWeight(.semibold)
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
                .unredacted()
                .accessibilityIdentifier("Item Title")
            if let genres = viewModel.content?.itemGenres, !genres.isEmpty {
                Text(genres)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontDesign(.rounded)
            }
            if let info = viewModel.content?.itemQuickInfo, !info.isEmpty {
                Text(info)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontDesign(.rounded)
            }
            
            HStack {
                Spacer()
                if type == .movie {
                    watchButton
                } else {
                    favoriteButton
                }
                watchlistButton
                    .keyboardShortcut("l", modifiers: [.option])
                    .padding(.horizontal)
                listButton
                Spacer()
            }
            .padding([.top, .horizontal])

            watchedDateCaption
            
            OverviewBoxView(overview: viewModel.content?.itemOverview,
                            title: title).padding()
            
            if let season = viewModel.content?.seasons {
                SeasonListView(
                    showID: id,
                    showTitle: title,
                    seasons: season,
                    isInWatchlist: $viewModel.isInWatchlist,
                    showCover: viewModel.content?.cardImageMedium
                )
                .padding([.top, .horizontal], .zero)
                .padding(.bottom)
            }
            
            WatchProvidersList(id: id, type: type)
            
            TrailerListView(trailers: viewModel.trailers)
            
            CastListView(credits: viewModel.credits)
            
            HorizontalItemContentListView(items: viewModel.recommendations,
                                          title: String(localized: "Recommendations"),
                                          showPopup: $showPopup,
                                          popupType: $popupType,
                                          displayAsCard: true)
            
            infoBox(item: viewModel.content, type: type).padding()
            
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack { }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .actionPopup(isShowing: $showPopup, for: popupType)
    }
#endif
    
#if !os(tvOS)
    private var sizeBasedPadMacView: some View {
        VStack {
            
            // Header
            HStack {
                poster
                
                VStack(alignment: .leading) {
                    Text(title)
                        .fontWeight(.semibold)
                        .font(.title)
                        .padding(.bottom)
                    HStack {
                        Text(viewModel.content?.itemOverview ?? "")
                            .lineLimit(10)
                            .onTapGesture {
                                showOverview.toggle()
                            }
                        Spacer()
                    }
                    .frame(maxWidth: 460)
                    .padding(.bottom)
                    .popover(isPresented: $showOverview) {
                        if let overview = viewModel.content?.itemOverview {
                            VStack {
                                ScrollView {
                                    Text(overview)
                                        .padding()
                                }
                            }
                            .frame(minWidth: 200, maxWidth: 400, minHeight: 200, maxHeight: 300, alignment: .center)
                        }
                    }
                    
                    // Actions
                    HStack {
                        watchlistButton
                            .padding(.trailing)
                        
                        if viewModel.isInWatchlist {
                            if type == .movie {
                                watchButton
                            } else {
                                favoriteButton
                            }
                            
                            listButton
                                .padding(.horizontal)
                        }
                    }

                    watchedDateCaption
                }
                .frame(width: 360)
                
                ViewThatFits {
                    quickInformationBoxView
                        .frame(width: 280)
                        .padding(.horizontal)
                        .onAppear {
                            showInfoBox = false
                            isSideInfoPanelShowed = true
                        }
                        .onDisappear {
                            showInfoBox = true
                            isSideInfoPanelShowed = false
                        }
                    VStack {
                        Text("")
                    }
                }
                
                Spacer()
            }
            .padding(.leading)
            
            if let season = viewModel.content?.seasons {
                SeasonListView(
                    showID: id,
                    showTitle: title,
                    seasons: season,
                    isInWatchlist: $viewModel.isInWatchlist,
                    showCover: viewModel.content?.cardImageMedium
                ).padding(0)
            }
            
            TrailerListView(trailers: viewModel.trailers)
            
            WatchProvidersList(id: id, type: type)
            
            CastListView(credits: viewModel.credits)
            
            HorizontalItemContentListView(items: viewModel.recommendations,
                                          title: String(localized: "Recommendations"),
                                          showPopup: $showPopup,
                                          popupType: $popupType,
                                          displayAsCard: true)
            if showInfoBox {
                GroupBox("Information") {
                    quickInformationBoxView
                }
                .padding()
                
            }
        }
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#elseif os(macOS)
        .navigationTitle(title)
#endif
        .task {
            if !isSideInfoPanelShowed && !showInfoBox { showInfoBox = true }
        }
    }
#endif
    
#if os(tvOS)
    private var sizeBasedTVView: some View {
        VStack {
            HStack {
                Spacer()
                poster
                
                VStack(alignment: .leading) {
                    Text(title)
                        .fontWeight(.semibold)
                        .font(.title2)
                        .padding(.bottom)
                    Button {
                        showOverview.toggle()
                    } label: {
                        HStack {
                            Text(viewModel.content?.itemOverview ?? String())
                                .font(.callout)
                                .fontDesign(.rounded)
                                .lineLimit(10)
                                .onTapGesture {
                                    showOverview.toggle()
                                }
                            Spacer()
                        }
                        .frame(maxWidth: 700)
                        .padding(.bottom)
                    }
                    .buttonStyle(.plain)
                    .sheet(isPresented: $showOverview) {
                        NavigationStack {
                            ScrollView {
                                Text(viewModel.content?.itemOverview ?? "")
                                    .padding()
                            }
                            .navigationTitle(title)
                        }
                    }
                    
                    // Actions row
                    HStack {
                        VStack {
                            watchlistButton
                                .buttonStyle(.borderedProminent)
                                .prefersDefaultFocus(in: tvOSActionNamespace)
                                .focused($isWatchlistButtonFocused)
                            Text(viewModel.isInWatchlist ? "Remove" : "Add")
                                .padding(.top, 2)
                                .font(.caption)
                                .lineLimit(1)
                                .opacity(isWatchlistInFocus ? 1 : 0)
                        }
                        .focused($isWatchlistInFocus)
                        
                        // Watch button
                        VStack {
                            watchButton
                            Text("Watch")
                                .padding(.top, 2)
                                .font(.caption)
                                .lineLimit(1)
#if os(tvOS)
                                .opacity(isWatchInFocus ? 1 : 0)
#endif
                            
                        }
                        
                        // Favorite button
                        VStack {
                            favoriteButton
                            Text("Favorite")
                                .padding(.top, 2)
                                .font(.caption)
                                .lineLimit(1)
#if os(tvOS)
                                .opacity(isFavoriteInFocus ? 1 : 0)
#endif
                        }
                    }

                    watchedDateCaption
                }
                .frame(width: 700)
                
                quickInformationBoxView
                    .frame(width: 400)
                    .padding(.trailing)
                
                Spacer()
            }
            
            if let seasons = viewModel.content?.seasons {
                SeasonListView(
                    showID: id,
                    showTitle: title,
                    seasons: seasons,
                    isInWatchlist: $viewModel.isInWatchlist,
                    showCover: viewModel.content?.cardImageLarge
                )
            }
            
            TrailerListView(trailers: viewModel.trailers)
            
            WatchProvidersList(id: id, type: type)
#if os(tvOS)
                .padding(.leading, 64)
#endif
            
            HorizontalItemContentListView(items: viewModel.recommendations,
                                          title: String(localized: "Recommendations"),
                                          showPopup: $showPopup,
                                          popupType: $popupType,
                                          displayAsCard: true)
            
            CastListView(credits: viewModel.credits)
                .padding(.bottom)
        }
        .onAppear(perform: setupInitialFocus)
        .ignoresSafeArea(.all, edges: .horizontal)
    }
#endif
    
    private var poster: some View {
        LazyImage(url: viewModel.content?.posterImageMedium) { state in
            if let image = state.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    Rectangle().fill(.gray.gradient)
                    VStack {
                        Image(systemName: "popcorn")
                            .font(.title)
                            .fontWidth(.expanded)
                            .foregroundColor(.white.opacity(0.8))
                            .unredacted()
                            .padding()
                    }
                    .frame(width: 220, height: 300)
                    .padding()
                }
            }
        }
        .overlay {
            if !animationImage.isEmpty {
                ZStack {
                    Rectangle().fill(.thinMaterial)
                    Image(systemName: animationImage)
                        .symbolRenderingMode(.multicolor)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120, alignment: .center)
                        .scaleEffect(animateGesture ? 1.1 : 1)
                }
                .opacity(animateGesture ? 1 : 0)
            }
        }
        
        .frame(width: DrawingConstants.posterWidth, height: DrawingConstants.posterHeight)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onTapGesture(count: 2) {
            animate(for: store.gesture)
            viewModel.update(store.gesture)
        }
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 10)
        .padding()
        .accessibility(hidden: true)
    }
    
#if os(iOS)
    private var cover: some View {
        HeroImage(url: viewModel.content?.cardImageLarge,
                  title: title)
        .overlay {
            if !animationImage.isEmpty {
                ZStack {
                    Rectangle().fill(.ultraThinMaterial)
                    Image(systemName: animationImage)
                        .symbolRenderingMode(.multicolor)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120, alignment: .center)
                        .scaleEffect(animateGesture ? 1.1 : 1)
                }
                .opacity(animateGesture ? 1 : 0)
            }
        }
        .frame(width: DrawingConstants.coverWidth, height: DrawingConstants.coverHeight)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 10)
        .padding(.top)
        .padding(.bottom, 8)
        .accessibilityElement(children: .combine)
        .accessibility(hidden: true)
        .onTapGesture(count: 2) {
            animate(for: store.gesture)
            viewModel.update(store.gesture)
        }
    }
#endif
    
#if !os(tvOS)
    @ViewBuilder
    private func infoBox(item: ItemContent?, type: MediaType) -> some View {
        GroupBox("Information") {
            Section {
                infoView(title: String(localized: "Original Title"),
                         content: item?.originalItemTitle)
                if let numberOfSeasons = item?.numberOfSeasons, let numberOfEpisodes = item?.numberOfEpisodes {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Overview")
                                .font(.caption)
                            Text("\(numberOfSeasons) Seasons • \(numberOfEpisodes) Episodes")
                                .multilineTextAlignment(.leading)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                        Spacer()
                    }
                    .padding([.horizontal, .top], 2)
                }
                infoView(title: String(localized: "Run Time"),
                         content: item?.itemRuntime)
                infoView(title: String(localized: "Certification"),
                         content: item?.itemCertification)
                if type == .movie {
                    if let theatricalStringDate = item?.itemTheatricalString {
                        tappableInfoDisclosureRow(
                            title: String(localized: "Release Date"),
                            value: theatricalStringDate
                        ) {
                            showReleaseDateInfo.toggle()
                        }
                    }
                    
                } else {
                    infoView(title: String(localized: "First Air Date"),
                             content: item?.itemFirstAirDate)
                }
                CriticScoresSection(ratings: viewModel.criticRatings, fallbackTMDB: item?.itemRating)
                infoView(title: String(localized: "Status"),
                         content: item?.itemStatus.localizedTitle)
                infoView(title: String(localized: "Genres"),
                         content: item?.itemGenres)
                infoView(title: String(localized: "Region of Origin"),
                         content: item?.itemCountry)
                if let companies = item?.itemCompanies, let company = item?.itemCompany {
                    if !companies.isEmpty {
                        NavigationLink(value: companies) {
                            infoDisclosureRow(
                                title: String(localized: "Production Companies"),
                                value: company
                            )
                        }
#if os(macOS)
                        .buttonStyle(.link)
#endif
                    }
                } else {
                    infoView(title: String(localized: "Production Company"),
                             content: item?.itemCompany)
                }
            }
        }
        .groupBoxStyle(TransparentGroupBox())
    }
#endif
    
    @ViewBuilder
    private func infoView(title: String, content: String?) -> some View {
        if let content, !content.isEmpty {
            HStack {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.caption)
                    Text(content)
                        .multilineTextAlignment(.leading)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .accessibilityElement(children: .combine)
                Spacer()
            }
            .padding([.horizontal, .top], 2)
        } else {
            EmptyView()
        }
    }
}

extension ItemContentDetails {
    // MARK: Computed properties
#if !os(tvOS)
    private var cronicaUrl: URL? {
        guard let item = viewModel.content else { return nil }
        return AppWebsite.detailsURL(
            contentID: item.itemContentID,
            posterPath: item.posterPath,
            title: item.itemTitle
        )
    }
#endif
    
    // MARK: Action Buttons
    private var watchlistButton: some View {
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
#if os(macOS)
            Label(viewModel.isInWatchlist ? "Remove": "Add",
                  systemImage: viewModel.isInWatchlist ? "minus.circle.fill" : "plus.circle.fill")
            .symbolEffect(viewModel.isInWatchlist ? .bounce.down : .bounce.up,
                          value: viewModel.isInWatchlist)
#else
            VStack {
                Image(systemName: viewModel.isInWatchlist ? "minus.circle.fill" : "plus.circle.fill")
                    .symbolEffect(viewModel.isInWatchlist ? .bounce.down : .bounce.up,
                                  value: viewModel.isInWatchlist)
                
#if !os(tvOS)
                Text(viewModel.isInWatchlist ? "Remove" : "Add")
                    .lineLimit(1)
                    .padding(.top, 2)
                    .font(.caption)
#endif
            }
#if !os(watchOS)
            .padding(.vertical, 4)
            .frame(width: DrawingConstants.buttonWidth, height: DrawingConstants.buttonHeight)
#else
            .padding(.vertical, 2)
#endif
#endif
        }
        .buttonStyle(.borderedProminent)
#if os(macOS)
        .controlSize(.large)
#elseif os(iOS)  || os(visionOS)
        .controlSize(.small)
        .applyHoverEffect()
#endif
        .disabled(viewModel.isLoading)
#if os(iOS) || os(macOS) || os(watchOS)
        .tint(viewModel.isInWatchlist ? .red.opacity(0.95) : store.appTheme.color)
#endif
#if os(iOS) || os(visionOS)
        .buttonBorderShape(.roundedRectangle(radius: DrawingConstants.buttonRadius))
#endif
        .confirmationDialog("Are You Sure?", isPresented: $showConfirmationPopup, titleVisibility: .visible) {
            Button("Confirm") { updateWatchlist() }
        }
        .accessibilityIdentifier("Watchlist Button")
    }
    
    @ViewBuilder
    private var watchedDateCaption: some View {
        if viewModel.isWatched, let watchedDateLabel = viewModel.watchedDateLabel {
            Button {
                showUserNotes = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                    Text("\(String(localized: "Watched")) \(watchedDateLabel)")
                }
                .font(.caption)
                .fontDesign(.rounded)
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityHint(String(localized: "Edit watched date in Review"))
            .padding(.top, 4)
        }
    }

    private var watchButton: some View {
        Button {
            requestWatchToggle()
        } label: {
#if os(macOS)
            Label("Watched",
                  systemImage: viewModel.isWatched ? "rectangle.badge.checkmark.fill" : "rectangle.badge.checkmark")
            .symbolEffect(viewModel.isWatched ? .bounce.down : .bounce.up,
                          value: viewModel.isWatched)
#else
            VStack {
                Image(systemName: viewModel.isWatched ? "rectangle.badge.checkmark.fill" : "rectangle.badge.checkmark")
                    .symbolEffect(viewModel.isWatched ? .bounce.down : .bounce.up,
                                  value: viewModel.isWatched)
                
#if !os(tvOS)
                Text("Watched")
                    .padding(.top, 2)
                    .font(.caption)
                    .lineLimit(1)
#endif
            }
            .padding(.vertical, 4)
            .frame(width: DrawingConstants.buttonWidth, height: DrawingConstants.buttonHeight)
#endif
        }
#if !os(tvOS)
        .keyboardShortcut("w", modifiers: [.option])
#endif
#if os(macOS)
        .controlSize(.large)
#elseif !os(tvOS)
        .controlSize(.small)
#endif
        .buttonStyle(.bordered)
        .buttonBorderShape(.roundedRectangle(radius: DrawingConstants.buttonRadius))
#if !os(visionOS)
        .tint(.primary)
#endif
#if os(iOS)
        .applyHoverEffect()
#elseif os(tvOS)
        .focused($isWatchInFocus)
#endif
    }

    private func requestWatchToggle() {
        if type == .tvShow,
           viewModel.isWatched,
           let contentID = viewModel.content?.itemContentID,
           let item = PersistenceController.shared.fetch(for: contentID),
           item.hasStartedWatching {
            showUnwatchConfirmation = true
            return
        }
        guard viewModel.updateWatched(resetEpisodeProgress: true) else {
            showNotReleasedAlert = true
            return
        }
        resetPopupAnimation()
        animatePopup(for: viewModel.isWatched ? .markedWatched : .removedWatched)
    }
    
    private var favoriteButton: some View {
        Button {
            viewModel.update(.favorite)
            resetPopupAnimation()
            if type == .movie {
                animatePopup(for: viewModel.isFavorite ? .markedFavorite : .removedFavorite)
                withAnimation { showPopup = true }
            }
            if viewModel.isFavorite, type == .tvShow {
                animateFavorite.toggle()
            }
        } label: {
#if os(macOS)
            Label("Favorite", systemImage: viewModel.isFavorite ? "heart.fill" : "heart")
                .symbolEffect(viewModel.isFavorite ? .bounce.down : .bounce.up,
                              value: viewModel.isFavorite)
                .changeEffect(
                    .spray(origin: UnitPoint(x: 0.25, y: 0.5)) {
                        Image(systemName: "heart")
                            .foregroundStyle(.red)
                    }, value: animateFavorite)
#else
            VStack {
                Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                    .symbolEffect(viewModel.isFavorite ? .bounce.down : .bounce.up,
                                  value: viewModel.isFavorite)
#if !os(tvOS)
                    .changeEffect(
                        .spray(origin: UnitPoint(x: 0.25, y: 0.5)) {
                            Image(systemName: "heart")
                                .foregroundStyle(.red)
                        }, value: animateFavorite)
#endif
#if !os(tvOS)
                Text("Favorite")
                    .padding(.top, 2)
                    .font(.caption)
                    .lineLimit(1)
#endif
            }
            .padding(.vertical, 4)
            .frame(width: DrawingConstants.buttonWidth, height: DrawingConstants.buttonHeight)
#endif
        }
#if !os(tvOS)
        .keyboardShortcut("f", modifiers: [.option])
#endif
#if os(macOS)
        .controlSize(.large)
#elseif !os(tvOS)
        .controlSize(.small)
#endif
        .buttonStyle(.bordered)
        .buttonBorderShape(.roundedRectangle(radius: DrawingConstants.buttonRadius))
#if !os(visionOS)
        .tint(.primary)
#endif
#if os(iOS)
        .applyHoverEffect()
#elseif os(tvOS)
        .focused($isFavoriteInFocus)
#endif
    }
    
    private var listButton: some View {
        Button {
            showCustomList.toggle()
        } label: {
#if os(macOS)
            Label("Lists", systemImage: viewModel.isItemAddedToAnyList ? "rectangle.on.rectangle.angled.fill" : "rectangle.on.rectangle.angled")
#else
            VStack {
                Image(systemName: viewModel.isItemAddedToAnyList ? "rectangle.on.rectangle.angled.fill" : "rectangle.on.rectangle.angled")
                Text("Lists")
                    .padding(.top, 2)
                    .font(.caption)
                    .lineLimit(1)
            }
            .padding(.vertical, 4)
            .frame(width: DrawingConstants.buttonWidth, height: DrawingConstants.buttonHeight)
#endif
        }
#if !os(tvOS) && !os(macOS)
        .controlSize(.small)
#elseif !os(tvOS)
        .controlSize(.large)
#endif
        .buttonStyle(.bordered)
        .buttonBorderShape(.roundedRectangle(radius: DrawingConstants.buttonRadius))
#if !os(visionOS)
        .tint(.primary)
#endif
#if os(iOS)
        .applyHoverEffect()
#endif
        .disabled(!viewModel.isInWatchlist)
    }
    
#if !os(tvOS)
    // MARK: Toolbar
    @ViewBuilder
    private var watchButtonToolbar: some View {
        Button(viewModel.isWatched ? "Unwatched" : "Watched",
               systemImage: viewModel.isWatched ? "rectangle.badge.checkmark.fill" : "rectangle.badge.checkmark") {
            requestWatchToggle()
        }.symbolEffect(.bounce.down, value: viewModel.isWatched)
    }
    
    @ViewBuilder
    private var favoriteButtonToolbar: some View {
        Button(viewModel.isFavorite ? "Unfavorite" : "Favorite",
               systemImage: viewModel.isFavorite ? "heart.fill" : "heart") {
            viewModel.update(.favorite)
            animatePopup(for: viewModel.isFavorite ? .markedFavorite : .removedFavorite)
        }.symbolEffect(.bounce.down, value: viewModel.isFavorite)
    }
    
    @ViewBuilder
    private var pinButtonToolbar: some View {
        Button(viewModel.isPin ? "Unpin" : "Pin",
               systemImage: viewModel.isPin ? "pin.fill" : "pin") {
            viewModel.update(.pin)
            animatePopup(for: viewModel.isPin ? .markedPin : .removedPin)
        }.symbolEffect(.bounce.down, value: viewModel.isPin)
    }
    
    @ViewBuilder
    private var archiveButtonToolbar: some View {
        Button(viewModel.isArchive ? "Unarchive" : "Archive",
               systemImage: viewModel.isArchive ? "archivebox.fill" : "archivebox") {
            viewModel.update(.archive)
            animatePopup(for: viewModel.isArchive ? .markedArchive : .removedArchive)
        }.symbolEffect(.bounce.down, value: viewModel.isArchive)
    }
    
    private var reviewButtonToolbar: some View {
        Button("Review", systemImage: "note.text") { showUserNotes.toggle() }
    }

    @ViewBuilder
    private var muteNotificationsToolbar: some View {
        Button(viewModel.isNotificationsMuted ? "Unmute Notifications" : "Mute Notifications",
               systemImage: viewModel.isNotificationsMuted ? "bell.slash.fill" : "bell.slash") {
            viewModel.toggleNotificationsMuted()
        }
    }

    @ViewBuilder
    private var hideFromUpNextToolbar: some View {
        if type == .tvShow {
            Button(viewModel.isHiddenFromUpNext ? "Show in Up Next" : "Hide from Up Next",
                   systemImage: viewModel.isHiddenFromUpNext ? "eye" : "eye.slash") {
                viewModel.toggleHideFromUpNext()
            }
        }
    }

    @ViewBuilder
    private var hideFromWatchlistToolbar: some View {
        Button(viewModel.isHiddenFromWatchlist ? "Unhide from Watchlist" : "Hide from Watchlist",
               systemImage: viewModel.isHiddenFromWatchlist ? "eye" : "eye.slash") {
            viewModel.toggleHideFromWatchlist()
        }
    }
    
    @ViewBuilder
    private var shareButton: some View {
        switch store.shareLinkPreference {
        case .tmdb: if let url = viewModel.content?.itemURL { ShareLink(item: url) }
        case .cronica: if let cronicaUrl {
            ShareLink(item: cronicaUrl, message: Text(title))
        }
        }
    }
    
    private var openInMenu: some View {
        Menu("Open in",
             systemImage: "ellipsis.circle") {
            
            if let homepage = viewModel.content?.homepage, let url = URL(string: homepage) {
                Button("Official Website") {
                    openUrl(for: url)
                }
            }
            Button("The Movie Database") {
                guard let url = viewModel.content?.itemURL else { return }
                openUrl(for: url)
            }
        }
             .labelStyle(.titleOnly)
#if os(visionOS)
             .menuStyle(.button)
             .buttonStyle(.bordered)
#endif
    }
    
    private var toolbarRow: some View {
        HStack {
            shareButton
            if type == .movie {
                favoriteButtonToolbar
                    .disabled(!viewModel.isInWatchlist)
            } else {
                watchButtonToolbar
                    .disabled(!viewModel.isInWatchlist)
            }
            archiveButtonToolbar
                .disabled(!viewModel.isInWatchlist)
            pinButtonToolbar
                .disabled(!viewModel.isInWatchlist)
            reviewButtonToolbar
                .disabled(!viewModel.isInWatchlist)
            if viewModel.isInWatchlist {
                muteNotificationsToolbar
                hideFromWatchlistToolbar
                hideFromUpNextToolbar
            }
            openInMenu
        }
        .disabled(viewModel.isLoading ? true : false)
    }
    
#if !os(macOS)
    private var moreMenu: some View {
        Menu("More Options", systemImage: "ellipsis.circle") {
#if os(visionOS)
            if viewModel.isInWatchlist {
                if type == .movie {
                    favoriteButtonToolbar
                } else {
                    watchButtonToolbar
                }
                archiveButtonToolbar
                pinButtonToolbar
                reviewButtonToolbar
                muteNotificationsToolbar
                hideFromWatchlistToolbar
                hideFromUpNextToolbar
            }
            openInMenu
#else
            if horizontalSizeClass == .compact {
                if viewModel.isInWatchlist {
                    if type == .movie {
                        favoriteButtonToolbar
                    } else {
                        watchButtonToolbar
                    }
                    archiveButtonToolbar
                    pinButtonToolbar
                    reviewButtonToolbar
                    muteNotificationsToolbar
                    hideFromWatchlistToolbar
                    hideFromUpNextToolbar
                }
            } else if viewModel.isInWatchlist {
                muteNotificationsToolbar
                hideFromWatchlistToolbar
                hideFromUpNextToolbar
            }
            openInMenu
#endif
            
        }
        .labelStyle(.iconOnly)
    }
#endif
#endif
    
    // MARK: Information box
    private var quickInformationBoxView: some View {
        VStack(alignment: .leading) {
            infoLabel(title: String(localized: "Original Title"),
                      content: viewModel.content?.originalItemTitle)
            infoLabel(title: String(localized: "Run Time"),
                      content: viewModel.content?.itemRuntime)
            infoLabel(title: String(localized: "Certification"),
                      content: viewModel.content?.itemCertification)
            if let numberOfSeasons = viewModel.content?.numberOfSeasons, let numberOfEpisodes = viewModel.content?.numberOfEpisodes {
                infoLabel(title: String(localized: "Overview"),
                          content: "\(numberOfSeasons) Seasons • \(numberOfEpisodes) Episodes")
            }
            if viewModel.content?.itemContentMedia == .movie {
                if let theatricalStringDate = viewModel.content?.itemTheatricalString {
                    tappableInfoDisclosureRow(
                        title: String(localized: "Release Date"),
                        value: theatricalStringDate
                    ) {
                        showReleaseDateInfo.toggle()
                    }
                }
                
            } else {
                infoLabel(title: String(localized: "First Air Date"),
                          content: viewModel.content?.itemFirstAirDate)
            }
            CriticScoresSection(ratings: viewModel.criticRatings, fallbackTMDB: viewModel.content?.itemRating)
            infoLabel(title: String(localized: "Region of Origin"),
                      content: viewModel.content?.itemCountry)
            infoLabel(title: String(localized: "Genres"),
                      content: viewModel.content?.itemGenres)
            if let companies = viewModel.content?.itemCompanies,
               let company = viewModel.content?.itemCompany, !companies.isEmpty {
                NavigationLink(value: companies) {
                    infoDisclosureRow(
                        title: String(localized: "Production Companies"),
                        value: company
                    )
                }
                .buttonStyle(.plain)
            } else {
                infoLabel(title: String(localized: "Production Company"),
                          content: viewModel.content?.itemCompany)
            }
            infoLabel(title: String(localized: "Status"),
                      content: viewModel.content?.itemStatus.localizedTitle)
        }
        .sheet(isPresented: $showReleaseDateInfo) {
            let productionRegion = viewModel.content?.productionCountries?.first?.iso31661 ?? "US"
            DetailedReleaseDateView(item: viewModel.content?.releaseDates?.results, productionRegion: productionRegion,
                                    dismiss: $showReleaseDateInfo)
#if os(macOS)
            .frame(width: 400, height: 300, alignment: .center)
#else
            .appTint()
            .appTheme()
#endif
        }
    }
    
    private func infoDisclosureRow(title: String, value: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                infoTitleWithChevron(title)
                Text(value)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            Spacer()
        }
        .padding([.horizontal, .top], 2)
    }

    @ViewBuilder
    private func infoTitleWithChevron(_ title: String) -> some View {
        HStack(spacing: 2) {
            Text(title)
                .font(.caption)
#if !os(tvOS)
            Image(systemName: "chevron.right")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
#endif
        }
    }

    private func tappableInfoDisclosureRow(
        title: String,
        value: String,
        action: @escaping () -> Void
    ) -> some View {
        infoDisclosureRow(title: title, value: value)
            .contentShape(Rectangle())
            .onTapGesture(perform: action)
    }
    
    @ViewBuilder
    private func infoLabel(title: String, content: String?) -> some View {
        if let content {
            HStack {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.caption)
                    Text(content)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .accessibilityElement(children: .combine)
                Spacer()
            }
            .padding([.horizontal, .top], 2)
        } else {
            EmptyView()
        }
    }
    
    // MARK: Functions
    private func updateWatchlist() {
        guard let item = viewModel.content else { return }
        viewModel.updateWatchlist(with: item)
        let settings = SettingsStore.shared
        if settings.openListSelectorOnAdding && viewModel.isInWatchlist {
            showCustomList.toggle()
        }
    }
    
    private func resetPopupAnimation() {
        if showPopup { showPopup = false }
        if popupType != nil { popupType = nil }
    }
    
    private func animatePopup(for action: ActionPopupItems) {
        resetPopupAnimation()
        popupType = action
        withAnimation {
            showPopup = true
        }
    }
    
#if os(tvOS)
    private func setupInitialFocus() {
        if !hasFocused {
            DispatchQueue.main.async {
                isWatchlistButtonFocused = true
                hasFocused = true
            }
        }
    }
#endif
    
    private func animate(for type: UpdateItemProperties) {
        switch type {
        case .watched: animationImage = viewModel.isWatched ? "rectangle.badge.checkmark" : "rectangle.badge.checkmark.fill"
        case .favorite: animationImage = viewModel.isFavorite ? "heart.slash.fill" : "heart.fill"
        case .pin: animationImage = viewModel.isPin ? "pin.slash" : "pin"
        case .archive: animationImage = viewModel.isArchive ? "archivebox.fill" : "archivebox"
        }
        withAnimation(.bouncy) { animateGesture.toggle() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.bouncy) { animateGesture = false }
        }
    }
    
#if !os(tvOS)
    private func openUrl(for url: URL) {
        openURL(url)
    }
#endif
}

private struct DrawingConstants {
    static let shadowRadius: CGFloat = 12
#if os(iOS)
    static let posterWidth: CGFloat = 200
    static let posterHeight: CGFloat = 300
    static let coverWidth: CGFloat = 360
    static let coverHeight: CGFloat = 210
#elseif os(tvOS)
    static let posterWidth: CGFloat = 450
    static let posterHeight: CGFloat = 700
#elseif os(macOS) || os(visionOS)
    static let posterWidth: CGFloat = 280
    static let posterHeight: CGFloat = 440
#endif
    static let imageRadius: CGFloat = 12
    static let buttonWidth: CGFloat = 75
    static let buttonHeight: CGFloat = 50
    static let buttonRadius: CGFloat = 12
}

#Preview {
    NavigationStack {
        ItemContentDetails(title: ItemContent.example.itemTitle,
                           id: ItemContent.example.id,
                           type: .movie)
    }
}
