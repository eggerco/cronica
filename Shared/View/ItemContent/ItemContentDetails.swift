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
    
    // MARK: Animation properties
    @State private var animateFavorite = false
    @State private var heroAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        ScrollView {
            VStack {
#if os(macOS) || os(visionOS)
                sizeBasedPadMacView
#elseif os(iOS)
                if UIDevice.isIPad {
                    sizeBasedPadMacView
                } else {
                    sizedBasedPhoneView
                }
#elseif os(tvOS)
                sizeBasedTVView
#endif
            }
        }
#if !os(tvOS)
        .toolbar {
#if os(iOS)
            if UIDevice.isIPad {
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
        .overlay { if viewModel.isLoading { ProgressView().padding().unredacted() } }
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
        .redacted(reason: viewModel.isLoading ? .placeholder : [])
        .alert("Error", isPresented: $viewModel.showErrorAlert) {
            Button("Cancel") { }
            Button("Retry") { Task { await viewModel.load(id: id, type: type) } }
        } message: {
            Text(viewModel.errorMessage)
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
        .sheet(isPresented: $showUserNotes) {
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
        VStack(spacing: 0) {
            if store.usePostersAsCover || viewModel.showPoster {
                poster
                phoneTitleBlock(alignment: .center, light: false)
                    .padding(.top, CronicaDesign.Spacing.sm)
                phoneActionCluster
                    .padding(.top, CronicaDesign.Spacing.md)
            } else {
                cinematicHero
            }

            OverviewBoxView(overview: viewModel.content?.itemOverview,
                            title: title)
                .padding(.horizontal, CronicaDesign.Spacing.md)
                .padding(.top, CronicaDesign.Spacing.md)

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
                                          title: NSLocalizedString("Recommendations", comment: ""),
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
        .toolbarBackground(.hidden, for: .navigationBar)
        .actionPopup(isShowing: $showPopup, for: popupType)
    }

    private var cinematicHero: some View {
        ZStack(alignment: .bottomLeading) {
            cover
                .scaleEffect(heroAppeared || reduceMotion ? 1 : 1.06)
            CronicaDesign.Atmosphere.gradient
                .allowsHitTesting(false)
            VStack(alignment: .leading, spacing: CronicaDesign.Spacing.sm) {
                phoneTitleBlock(alignment: .leading, light: true)
                phoneActionCluster
            }
            .padding(.horizontal, CronicaDesign.Spacing.lg)
            .padding(.bottom, CronicaDesign.Spacing.lg)
            .opacity(heroAppeared ? 1 : 0)
            .offset(y: heroAppeared || reduceMotion ? 0 : 16)
        }
        .frame(height: CronicaDesign.Atmosphere.detailHeroHeight)
        .frame(maxWidth: .infinity)
        .clipped()
        .onAppear {
            if reduceMotion {
                heroAppeared = true
            } else {
                withAnimation(CronicaDesign.Motion.hero) {
                    heroAppeared = true
                }
            }
        }
    }

    @ViewBuilder
    private func phoneTitleBlock(alignment: HorizontalAlignment, light: Bool) -> some View {
        VStack(alignment: alignment, spacing: CronicaDesign.Spacing.xxs) {
            Text(title)
                .multilineTextAlignment(alignment == .leading ? .leading : .center)
                .lineLimit(3)
                .font(CronicaDesign.Typography.display())
                .foregroundStyle(light ? .white : .primary)
                .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .center)
                .padding(.horizontal, alignment == .center ? CronicaDesign.Spacing.sm : 0)
                .unredacted()
            if let genres = viewModel.content?.itemGenres, !genres.isEmpty {
                Text(genres)
                    .font(CronicaDesign.Typography.caption())
                    .foregroundStyle(light ? .white.opacity(0.8) : .secondary)
            }
            if let info = viewModel.content?.itemQuickInfo, !info.isEmpty {
                Text(info)
                    .font(CronicaDesign.Typography.caption())
                    .foregroundStyle(light ? .white.opacity(0.7) : .secondary)
            }
        }
    }

    private var phoneActionCluster: some View {
        HStack(spacing: CronicaDesign.Spacing.sm) {
            if type == .movie {
                watchButton
            } else {
                favoriteButton
            }
            watchlistButton
                .keyboardShortcut("l", modifiers: [.option])
            listButton
        }
        .padding(.vertical, CronicaDesign.Spacing.xs)
        .padding(.horizontal, CronicaDesign.Spacing.sm)
        .cronicaGlassSurface()
        .padding(.horizontal, CronicaDesign.Spacing.md)
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
                                          title: NSLocalizedString("Recommendations", comment: ""),
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
                                          title: NSLocalizedString("Recommendations", comment: ""),
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
                  title: title,
                  fullBleed: true)
        .overlay {
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
        .frame(maxWidth: .infinity)
        .frame(height: CronicaDesign.Atmosphere.detailHeroHeight)
        .clipped()
        .accessibilityElement(children: .combine)
        .accessibilityHidden(true)
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
                infoView(title: NSLocalizedString("Run Time", comment: ""),
                         content: item?.itemRuntime)
                if type == .movie {
                    if let theatricalStringDate = item?.itemTheatricalString {
                        HStack {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("Release Date")
                                        .font(.caption)
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Text(theatricalStringDate)
                                    .lineLimit(1)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .accessibilityElement(children: .combine)
                            Spacer()
                        }
                        .padding([.horizontal, .top], 2)
                        .onTapGesture {
                            showReleaseDateInfo.toggle()
                        }
                    }
                    
                } else {
                    infoView(title: NSLocalizedString("First Air Date",
                                                      comment: ""),
                             content: item?.itemFirstAirDate)
                }
                infoView(title: NSLocalizedString("Ratings Score", comment: ""),
                         content: item?.itemRating)
                infoView(title: NSLocalizedString("Status",
                                                  comment: ""),
                         content: item?.itemStatus.localizedTitle)
                infoView(title: NSLocalizedString("Genres", comment: ""),
                         content: item?.itemGenres)
                infoView(title: NSLocalizedString("Region of Origin",
                                                  comment: ""),
                         content: item?.itemCountry)
                if let companies = item?.itemCompanies, let company = item?.itemCompany {
                    if !companies.isEmpty {
                        NavigationLink(value: companies) {
                            HStack {
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text("Production Companies")
                                            .font(.caption)
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Text(company)
                                        .multilineTextAlignment(.leading)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .accessibilityElement(children: .combine)
                                Spacer()
                            }
                            .padding([.horizontal, .top], 2)
                        }
#if os(macOS)
                        .buttonStyle(.link)
#endif
                    }
                } else {
                    infoView(title: NSLocalizedString("Production Company",
                                                      comment: ""),
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
        let encodedTitle = item.itemTitle.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let posterPath = item.posterPath ?? String()
        let encodedPoster = posterPath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        return URL(string: "https://www.oncronica.com/details?id=\(item.itemContentID)&img=\(encodedPoster ?? String())&title=\(encodedTitle ?? String())")
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
                HapticManager.shared.successHaptic()
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
    }
    
    private var watchButton: some View {
        Button {
            viewModel.update(.watched)
            resetPopupAnimation()
            animatePopup(for: viewModel.isWatched ? .markedWatched : .removedWatched)
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
            viewModel.update(.watched)
            animatePopup(for: viewModel.isWatched ? .markedWatched : .removedWatched)
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
            if viewModel.content?.hasIMDbUrl ?? false {
                Button("IMDb") {
                    guard let url = viewModel.content?.imdbUrl else { return }
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
            }
            openInMenu
#else
            if UIDevice.isIPhone {
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
            infoLabel(title: NSLocalizedString("Original Title",
                                               comment: ""),
                      content: viewModel.content?.originalItemTitle)
            infoLabel(title: NSLocalizedString("Run Time", comment: ""),
                      content: viewModel.content?.itemRuntime)
            if let numberOfSeasons = viewModel.content?.numberOfSeasons, let numberOfEpisodes = viewModel.content?.numberOfEpisodes {
                infoLabel(title: NSLocalizedString("Overview",
                                                   comment: ""),
                          content: "\(numberOfSeasons) Seasons • \(numberOfEpisodes) Episodes")
            }
            if viewModel.content?.itemContentMedia == .movie {
                if let theatricalStringDate = viewModel.content?.itemTheatricalString {
                    HStack {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Release Date")
                                    .font(.caption)
#if !os(tvOS)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
#endif
                            }
                            Text(theatricalStringDate)
                                .lineLimit(1)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                    .padding([.horizontal, .top], 2)
                    .onTapGesture {
                        showReleaseDateInfo.toggle()
                    }
                }
                
            } else {
                infoLabel(title: NSLocalizedString("First Air Date",
                                                   comment: ""),
                          content: viewModel.content?.itemFirstAirDate)
            }
            infoLabel(title: NSLocalizedString("Region of Origin",
                                               comment: ""),
                      content: viewModel.content?.itemCountry)
            infoLabel(title: NSLocalizedString("Genres", comment: ""),
                      content: viewModel.content?.itemGenres)
            if let companies = viewModel.content?.itemCompanies,
               let company = viewModel.content?.itemCompany, !companies.isEmpty {
                NavigationLink(value: companies) {
                    companiesLabel(company: company)
                }
                .buttonStyle(.plain)
            } else {
                infoLabel(title: NSLocalizedString("Production Company",
                                                   comment: ""),
                          content: viewModel.content?.itemCompany)
            }
            infoLabel(title: NSLocalizedString("Status",
                                               comment: ""),
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
    
    private func companiesLabel(company: String) -> some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text("Production Companies")
                        .font(.caption)
#if !os(tvOS)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
#endif
                }
                Text(company)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
            Spacer()
        }
        .padding([.horizontal, .top], 2)
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
        HapticManager.shared.successHaptic()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.bouncy) { animateGesture = false }
        }
    }
    
#if !os(tvOS)
    private func openUrl(for url: URL) {
#if os(iOS) || os(visionOS)
        UIApplication.shared.open(url)
#else
        NSWorkspace.shared.open(url)
#endif
    }
#endif
}

private struct DrawingConstants {
    static let shadowRadius: CGFloat = 12
#if os(iOS)
    static let posterWidth: CGFloat = UIDevice.isIPhone ? 200 : 280
    static let posterHeight: CGFloat = UIDevice.isIPhone ? 300 : 440
#elseif os(tvOS)
    static let posterWidth: CGFloat = 450
    static let posterHeight: CGFloat = 700
#elseif os(macOS) || os(visionOS)
    static let posterWidth: CGFloat = 280
    static let posterHeight: CGFloat = 440
#endif
    static let buttonWidth: CGFloat = 78
    static let buttonHeight: CGFloat = 52
    static let buttonRadius: CGFloat = CronicaDesign.Radius.media
}

#Preview {
    NavigationStack {
        ItemContentDetails(title: ItemContent.example.itemTitle,
                           id: ItemContent.example.id,
                           type: .movie)
    }
}
