//
//  ExploreView.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 30/04/22.
//

import SwiftUI
import CoreData

struct ExploreView: View {
    static let tag: Screens? = .explore
    @State private var showPopup = false
    @State private var onChanging = false
    @State private var showFilters = false
    @State private var popupType: ActionPopupItems?
    @StateObject private var settings = SettingsStore.shared
    
    private let service: NetworkService = NetworkService.shared
    @State private var items = [ItemContent]()
    @AppStorage("exploreViewSelectedGenre") private var selectedGenre: Int = 28
    @AppStorage("exploreViewSelectedMedia") private var selectedMedia: MediaType = .movie
    @State private var selectedSortBy: TMDBSortBy = .popularity
    @State private var selectedWatchProviders = [String]()
    @State private var isLoaded: Bool = false
    @State private var showErrorDialog: Bool = false
    @AppStorage("exploreViewHideAddedItems") private var hideAddedItems = false
    // MARK: Pagination Properties
    @State private var currentPage: Int = 0
    @State private var startPagination: Bool = false
    @State private var endPagination: Bool = false
    @State private var restartFetch: Bool = false
    // MARK: Recommendations
    @State private var isLoadingRecommendations = true
    @State private var recommendations = [ItemContent]()
    // MARK: Genres array.
    private let movies: [Genre] = [
        Genre(id: 28, name: String(localized: "Action")),
        Genre(id: 12, name: String(localized: "Adventure")),
        Genre(id: 16, name: String(localized: "Animation")),
        Genre(id: 35, name: String(localized: "Comedy")),
        Genre(id: 80, name: String(localized: "Crime")),
        Genre(id: 99, name: String(localized: "Documentary")),
        Genre(id: 18, name: String(localized: "Drama")),
        Genre(id: 10751, name: String(localized: "Family")),
        Genre(id: 14, name: String(localized: "Fantasy")),
        Genre(id: 36, name: String(localized: "History")),
        Genre(id: 27, name: String(localized: "Horror")),
        Genre(id: 10402, name: String(localized: "Music")),
        Genre(id: 9648, name: String(localized: "Mystery")),
        Genre(id: 10749, name: String(localized: "Romance")),
        Genre(id: 878, name: String(localized: "Science Fiction")),
        Genre(id: 53, name: String(localized: "Thriller")),
        Genre(id: 10752, name: String(localized: "War"))
    ]
    private let shows: [Genre] = [
        Genre(id: 10759, name: String(localized: "Action & Adventure")),
        Genre(id: 16, name: String(localized: "Animation")),
        Genre(id: 35, name: String(localized: "Comedy")),
        Genre(id: 80, name: String(localized: "Crime")),
        Genre(id: 99, name: String(localized: "Documentary")),
        Genre(id: 18, name: String(localized: "Drama")),
        Genre(id: 10762, name: String(localized: "Kids")),
        Genre(id: 9648, name: String(localized: "Mystery")),
        Genre(id: 10765, name: String(localized: "Sci-Fi & Fantasy"))
    ]
    @Environment(\.dismiss) var dismiss
#if os(tvOS)
    @AppStorage("selectedTabExplore") private var selectedForYouTab: ForYouTabType = .explore
#else
    @AppStorage("selectedTabExplore") private var selectedForYouTab: ForYouTabType = .recommendations
#endif
    var body: some View {
        VStack {
#if os(tvOS)
            exploreView
#else
            switch selectedForYouTab {
            case .recommendations:
                if isLoadingRecommendations {
                    CronicaLoadingPopupView()
                } else if !isLoadingRecommendations, recommendations.isEmpty {
                    ContentUnavailableView {
                        Label("Start watching to get recommendations...",
                              systemImage: "popcorn.fill")
                    } description: {
                        Text("Mark titles as watched to unlock a personal For You shelf.")
                    } actions: {
                        Button("Discover Movies & TV Shows") {
                            selectedForYouTab = .explore
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(settings.appTheme.color)
                    }
                    .padding(.horizontal, CronicaDesign.Spacing.lg)
                    .unredacted()
                } else {
                    switch settings.sectionStyleType {
                    case .list:
                        recommendationListStyle
                    case .card:
                        ScrollView {
                            recommendationsCardStyle
                        }
                        .scrollBounceBehavior(.basedOnSize)
                    case .poster:
                        ScrollView {
                            recommendationsPosterStyle
                        }
                        .scrollBounceBehavior(.basedOnSize)
                    }
                }
            case .explore: exploreView
            }
#endif
        }
        .sheet(isPresented: $showFilters) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: CronicaDesign.Spacing.lg) {
                        VStack(alignment: .leading, spacing: CronicaDesign.Spacing.sm) {
                            CronicaFilterSectionTitle(title: String(localized: "Options"))
                            CronicaFilterToggleRow(title: String(localized: "Hide Added Items"), isOn: $hideAddedItems)
                        }

                        VStack(alignment: .leading, spacing: CronicaDesign.Spacing.sm) {
                            CronicaFilterSectionTitle(title: String(localized: "Media"))
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: CronicaDesign.Spacing.xs) {
                                    ForEach(MediaType.allCases) { type in
                                        if type != .person {
                                            CronicaFilterChip(
                                                title: type.title,
                                                isSelected: selectedMedia == type
                                            ) {
                                                withAnimation(CronicaDesign.Motion.standard) {
                                                    selectedMedia = type
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, CronicaDesign.Spacing.md)
                            }
                        }

                        VStack(alignment: .leading, spacing: CronicaDesign.Spacing.sm) {
                            CronicaFilterSectionTitle(title: String(localized: "Genres"))
                            let genres = selectedMedia == .movie ? movies : shows
                            LazyVGrid(
                                columns: [GridItem(.adaptive(minimum: 120), spacing: CronicaDesign.Spacing.xs)],
                                spacing: CronicaDesign.Spacing.xs
                            ) {
                                ForEach(genres) { genre in
                                    CronicaFilterChip(
                                        title: genre.name ?? genre.itemTitle,
                                        isSelected: selectedGenre == genre.id
                                    ) {
                                        withAnimation(CronicaDesign.Motion.standard) {
                                            selectedGenre = genre.id
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, CronicaDesign.Spacing.md)
                        }
                    }
                    .padding(.bottom, CronicaDesign.Spacing.xl)
                }
                .navigationTitle("Filters")
#if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
#endif
                .toolbar {
#if !os(macOS)
                    ToolbarItem(placement: .topBarLeading) {
                        RoundedCloseButton {
                            showFilters = false
                        }
                    }
#else
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            showFilters = false
                        }
                    }
#endif
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .presentationDetents([.medium, .large])
            .cronicaFilterSheet()
            .unredacted()
#if os(iOS)
            .appTint()
            .appTheme()
#elseif os(macOS)
            .frame(width: 420, height: 520, alignment: .center)
#endif
        }
        .overlay { if !isLoaded { CronicaLoadingPopupView() } }
        .actionPopup(isShowing: $showPopup, for: popupType)
        .task { await load() }
        .navigationDestination(for: ItemContent.self) { item in
            ItemContentDetails(title: item.itemTitle, id: item.id, type: item.itemContentMedia, handleToolbar: false)
#if os(tvOS)
                .ignoresSafeArea(.all, edges: .horizontal)
#endif
        }
        .navigationDestination(for: Person.self) { person in
            PersonDetailsView(name: person.name, id: person.id)
#if os(tvOS)
                .ignoresSafeArea(.all, edges: .horizontal)
#endif
        }
        .navigationDestination(for: [String:[ItemContent]].self) { item in
            let keys = item.map { (key, _) in key }
            let value = item.map { (_, value) in value }
#if os(tvOS)
#else
            ItemContentSectionDetails(title: keys[0], items: value[0])
#endif
        }
        .navigationDestination(for: [Person].self) { items in
#if os(tvOS)
#else
            DetailedPeopleList(items: items)
#endif
        }
        .navigationDestination(for: ProductionCompany.self) { item in
            CompanyDetails(company: item)
        }
        .navigationDestination(for: [ProductionCompany].self) { item in
            CompaniesListView(companies: item)
        }
#if !os(tvOS) && !os(macOS)
        .navigationTitle(selectedForYouTab == .explore ? "Discover" : "For You")
#elseif os(tvOS)
        .ignoresSafeArea(.all, edges: .horizontal)
#endif
#if os(macOS)
        .navigationTitle("Discover")
#endif
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.automatic, for: .navigationBar)
#endif
        .onChange(of: hideAddedItems) { _, value in
            if value {
                hideItems()
            } else {
                onChanging = true
                Task {
                    await load()
                }
            }
        }
        .redacted(reason: !isLoaded ? .placeholder : [] )
        .toolbar {
#if !os(tvOS)
            ToolbarItem(placement: .principal) {
                Picker("For You", selection: $selectedForYouTab) {
                    ForEach(ForYouTabType.allCases) { item in
#if os(visionOS)
                        Label(item.localizedTitle, systemImage: item.toSFSymbols)
                            .labelStyle(.iconOnly)
                            .tag(item)
#else
                        Text(item.localizedTitle).tag(item)
#endif
                    }
                }
                .frame(width: 200)
                .pickerStyle(.segmented)
            }
            if selectedForYouTab != .recommendations {
#if !os(macOS)
                ToolbarItem {
                    Button("Filters",
                           systemImage: "line.3.horizontal.decrease.circle") {
                        showFilters.toggle()
                    }
                }
#else
                ToolbarItem(placement: .navigation) {
                    Button("Filters",
                           systemImage: "line.3.horizontal.decrease.circle") {
                        showFilters.toggle()
                    }
                }
#endif
            }
#endif
        }
        .onChange(of: selectedMedia) { _, value in
            onChanging = true
            var genre: Genre?
            if value == .tvShow {
                genre = shows.first
            } else {
                genre = movies.first
            }
            if let genre {
                selectedGenre = genre.id
            }
            Task { await load() }
        }
        .onChange(of: selectedGenre) {
            onChanging = true
            Task { await load() }
        }
    }
    
    @ViewBuilder
    private var exploreView: some View {
        if settings.sectionStyleType == .list {
            listStyle
        } else {
            ScrollViewReader { proxy in
                ScrollView {
#if os(tvOS)
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Discover")
                                .font(.title3)
                            Text(selectedMedia.title)
                                .font(.callout)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        Spacer()
                        Menu {
                            hideItemsToggle
                            selectMediaPicker
                            selectGenrePicker
                                .pickerStyle(.inline)
                        } label: {
                            Label("Filters", systemImage: "line.3.horizontal.decrease.circle")
                                .labelStyle(.iconOnly)
                        }
                    }
                    .padding(.horizontal, 64)
                    .unredacted()
#endif
                    
                    switch settings.sectionStyleType {
                    case .list: EmptyView()
                    case .poster: posterStyle
                    case .card: cardStyle
                    }
                }
                .onChange(of: onChanging) {
                    guard let first = items.first else { return }
                    withAnimation {
                        proxy.scrollTo(first.id, anchor: .topLeading)
                    }
                }
            }
        }
    }
    
#if !os(iOS)
    private var selectMediaPicker: some View {
        Picker(selection: $selectedMedia) {
            ForEach(MediaType.allCases) { type in
                if type != .person {
                    Text(type.title).tag(type)
                }
            }
        } label: {
            Text("Media Type")
        }
#if os(macOS)
        .pickerStyle(.inline)
#endif
    }
    
    private var selectGenrePicker: some View {
        Picker("Genres", selection: $selectedGenre) {
            if selectedMedia == .movie {
                ForEach(movies) { genre in
                    Text(genre.name!).tag(genre)
                }
            } else {
                ForEach(shows) { genre in
                    Text(genre.name!).tag(genre)
                }
            }
        }
#if os(iOS) || os(macOS)
        .pickerStyle(.inline)
#endif
    }
    
    private var hideItemsToggle: some View {
        Toggle("Hide Added Items", isOn: $hideAddedItems)
            .onChange(of: hideAddedItems) { _, value in
                if value {
                    hideItems()
                } else {
                    onChanging = true
                    Task {
                        await load()
                    }
                }
            }
    }
#endif
    
    private var listStyle: some View {
        Form {
            Section {
                List {
                    ForEach(items) { item in
                        ItemContentRowView(item: item, showPopup: $showPopup, popupType: $popupType)
                    }
                    if isLoaded && !endPagination {
                        CenterHorizontalView {
                            ProgressView("Loading")
                                .progressViewStyle(.circular)
                                .tint(settings.appTheme.color)
                                .padding(.horizontal)
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        loadMoreItems()
                                    }
                                }
                        }
                    }
                }
            }
        }
#if os(macOS)
        .formStyle(.grouped)
#endif
    }
    
    private var recommendationListStyle: some View {
        Form {
            Section {
                List {
                    ForEach(recommendations) { item in
                        ItemContentRowView(item: item, showPopup: $showPopup, popupType: $popupType)
                    }
                }
            }
        }
#if os(macOS)
        .formStyle(.grouped)
#endif
    }
    
    private var cardStyle: some View {
        LazyVGrid(columns: DrawingConstants.columns, spacing: 20) {
            ForEach(items) { item in
                ItemContentCardView(item: item, showPopup: $showPopup, popupType: $popupType)
                    .buttonStyle(.plain)
#if os(tvOS)
                    .padding(.bottom)
#endif
            }
            if isLoaded && !endPagination {
                CenterHorizontalView {
                    ProgressView()
                        .padding()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                loadMoreItems()
                            }
                        }
                }
            }
        }
        .padding()
    }
    
    private var recommendationsCardStyle: some View {
        LazyVGrid(columns: DrawingConstants.columns, spacing: 20) {
            ForEach(recommendations) { item in
                ItemContentCardView(item: item, showPopup: $showPopup, popupType: $popupType)
                    .buttonStyle(.plain)
#if os(tvOS)
                    .padding(.bottom)
#endif
            }
        }
        .padding()
    }
    
    private var recommendationsPosterStyle: some View {
        LazyVGrid(columns: settings.isCompactUI ? DrawingConstants.compactPosterColumns : DrawingConstants.posterColumns,
                  spacing: settings.isCompactUI ? DrawingConstants.compactSpacing : DrawingConstants.spacing) {
            ForEach(recommendations) { item in
                ItemContentPosterView(item: item, showPopup: $showPopup, popupType: $popupType)
                    .buttonStyle(.plain)
#if os(tvOS)
                    .padding(.bottom)
#endif
            }
        }.padding(.all, settings.isCompactUI ? 10 : nil)
    }
    
    private var posterStyle: some View {
        LazyVGrid(columns: settings.isCompactUI ? DrawingConstants.compactPosterColumns : DrawingConstants.posterColumns,
                  spacing: settings.isCompactUI ? DrawingConstants.compactSpacing : DrawingConstants.spacing) {
            ForEach(items) { item in
                ItemContentPosterView(item: item, showPopup: $showPopup, popupType: $popupType)
                    .buttonStyle(.plain)
#if os(tvOS)
                    .padding(.bottom)
#endif
            }
            if isLoaded && !endPagination {
                CenterHorizontalView {
                    ProgressView()
                        .padding()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                loadMoreItems()
                            }
                        }
                }
            }
        }.padding(.all, settings.isCompactUI ? 10 : nil)
    }
    
#if os(iOS) || os(macOS)
    private var styleOptions: some View {
#if os(macOS)
        Picker(selection: $settings.sectionStyleType) {
            ForEach(SectionDetailsPreferredStyle.allCases) { item in
                Text(item.title).tag(item)
            }
        } label: {
            Label("Style Picker", systemImage: "circle.grid.2x2")
                .labelStyle(.iconOnly)
        }
#else
        Menu {
            Picker(selection: $settings.sectionStyleType) {
                ForEach(SectionDetailsPreferredStyle.allCases) { item in
                    Text(item.title).tag(item)
                }
            } label: {
                Label("Style Picker", systemImage: "circle.grid.2x2")
            }
        } label: {
            Label("Style Picker", systemImage: "circle.grid.2x2")
                .labelStyle(.iconOnly)
        }
#endif
    }
#endif
}

#Preview {
    NavigationStack {
        ExploreView()
    }
}

private struct DrawingConstants {
#if os(macOS) || os(visionOS)
    static let posterColumns = [GridItem(.adaptive(minimum: 160))]
    static let columns = [GridItem(.adaptive(minimum: 240))]
#elseif os(tvOS)
    static let posterColumns = [GridItem(.adaptive(minimum: 260))]
    static let columns = [GridItem(.adaptive(minimum: 440))]
#else
    static let posterColumns  = [GridItem(.adaptive(minimum: 160))]
    static let columns = [GridItem(.adaptive(minimum: UIDevice.isIPad ? 240 : 160))]
#endif
    static let compactPosterColumns = [GridItem(.adaptive(minimum: 80))]
    static let compactSpacing: CGFloat = 20
    static let spacing: CGFloat = 10
}

extension ExploreView {
    private func load() async {
        if onChanging {
            restartFetch = true
            onChanging = false
            loadMoreItems()
        } else {
            loadMoreItems()
        }
        if recommendations.isEmpty {
            await fetchRecommendations()
        }
    }
    
    private func clearItems() {
        withAnimation {
            isLoaded = false
            items.removeAll()
        }
    }
    
    func hideItems() {
        let ids = fetchAllItemsIDs(selectedMedia)
        withAnimation {
            items.removeAll(where: { ids.contains($0.itemContentID)})
        }
    }
    
    func loadMoreItems(sortBy: TMDBSortBy = .popularity, reload: Bool = false) {
        if reload {
            withAnimation {
                items.removeAll()
                isLoaded = false
                currentPage = 0
                selectedSortBy = sortBy
            }
        }
        if restartFetch {
            currentPage = 0
            startPagination = true
            clearItems()
            restartFetch = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation {
                    self.isLoaded = true
                }
            }
        }
        currentPage += 1
        Task {
            await fetch()
        }
    }
    
    private func fetch() async {
        do {
            let result = try await service.fetchDiscover(type: selectedMedia,
                                                         page: currentPage,
                                                         genres: "\(selectedGenre)",
                                                         sort: selectedSortBy)
            if hideAddedItems {
                let ids = fetchAllItemsIDs(selectedMedia)
                items.append(contentsOf: result.filter { !ids.contains($0.itemContentID)})
            } else {
                for item in result {
                    if !items.contains(where: { $0.itemContentID == item.itemContentID} ) {
                        items.append(item)
                    }
                }
            }
            if currentPage == 1 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation {
                        self.isLoaded = true
                    }
                }
            }
            if result.isEmpty { endPagination = true }
            startPagination = false
        } catch {
            if Task.isCancelled { return }
            CronicaTelemetry.shared.handleMessage(error.localizedDescription,
                                                  for: "ExploreView.fetch()")
            showErrorDialog.toggle()
        }
    }
    
    private func fetchAllItemsIDs(_ media: MediaType) -> [String] {
        let persistence = PersistenceController.shared
        let request: NSFetchRequest<WatchlistItem> = WatchlistItem.fetchRequest()
        let typePredicate = NSPredicate(format: "contentType == %d", media.toInt)
        request.predicate = typePredicate
        do {
            let list = try persistence.container.viewContext.fetch(request)
            var ids = [String]()
            for item in list {
                ids.append(item.itemContentID)
            }
            return ids
        } catch {
            if Task.isCancelled { return [] }
            return []
        }
    }
    
    // MARK: Recommendation System
    // This is a very simple recommendation system, it the recommendation endpoint from TMDb API
    // to fetch the recommendations from watched or favorite items, then it filters out
    // some content without image or that contains NSFW keywords.
    
    /// Get the items which recommendations will be based at, these items must be watched OR favorite.
    /// - Returns: Returns a shuffled array of WatchlistItems that matches the criteria of watched OR favorite.
    private func fetchBasedRecommendationItems() -> [WatchlistItem] {
        let context = PersistenceController.shared.container.newBackgroundContext()
        let request: NSFetchRequest<WatchlistItem> = WatchlistItem.fetchRequest()
        let watchedPredicate = NSPredicate(format: "watched == %d", true)
        let watchingPredicate = NSPredicate(format: "isWatching == %d", true)
        request.predicate = NSCompoundPredicate(type: .or, subpredicates: [watchingPredicate, watchedPredicate])
        guard let list = try? context.fetch(request) else { return [] }
        let items = list.shuffled().prefix(8)
        return items.shuffled()
    }
    
    /// Gets all the IDs from watched content saved on Core Data.
    private func fetchWatchedIDs() -> Set<String> {
        do {
            var watchedIds: Set<String> = []
            let context = PersistenceController.shared.container.newBackgroundContext()
            let request: NSFetchRequest<WatchlistItem> = WatchlistItem.fetchRequest()
            let watchedPredicate = NSPredicate(format: "watched == %d", true)
            let watchingPredicate = NSPredicate(format: "isWatching == %d", true)
            request.predicate = NSCompoundPredicate(type: .or,
                                                    subpredicates: [watchedPredicate, watchingPredicate])
            let list = try context.fetch(request)
            if !list.isEmpty {
                for item in list {
                    watchedIds.insert(item.itemContentID)
                }
            }
            return watchedIds
        } catch {
            return []
        }
    }
    
    private func fetchRecommendations() async {
        var recommendations = [ItemContent]()
        let itemsWatched = fetchBasedRecommendationItems()
        var itemsToFetchFrom = [[Int:MediaType]]()
        for item in itemsWatched {
            itemsToFetchFrom.append([item.itemId:item.itemMedia])
        }
        for item in itemsToFetchFrom {
            let results = await getRecommendations(for: item)
            if let results {
                for result in results {
                    if !recommendations.contains(where: { $0.itemContentID == result.itemContentID }) {
                        recommendations.append(result)
                    }
                }
            }
        }
        let content = await filterRecommendationsItems(recommendations)
        self.recommendations = content.sorted { $0.itemPopularity > $1.itemPopularity }
        await MainActor.run {
            withAnimation { self.isLoadingRecommendations = false }
        }
    }
    
    private func getRecommendations(for item: [Int:MediaType]) async -> [ItemContent]? {
        guard let (id, type) = item.first else { return nil }
        let result = try? await service.fetchItems(from: "\(type.rawValue)/\(id)/recommendations")
        return result
    }
    
    /// Filters out recommendations from items without images and that matches NSFW keywords.
    /// - Parameter items: The items to be filtered.
    /// - Returns: The items filtered out.
    private func filterRecommendationsItems(_ items: [ItemContent]) async -> Set<ItemContent> {
        let watchedItems = fetchWatchedIDs()
        var result = Set<ItemContent>()
        for item in items {
            if item.posterPath != nil, item.backdropPath != nil {
                result.insert(item)
            }
        }
        let filteredWatched = result.filter { !watchedItems.contains($0.itemContentID) }
        return filteredWatched
    }
}

enum ForYouTabType: String, Identifiable, Codable, Hashable, CaseIterable {
    var id: String { rawValue }
    case recommendations, explore
    
    var localizedTitle: String {
        switch self {
        case .recommendations: NSLocalizedString("For You", comment: "")
        case .explore: NSLocalizedString("Discover", comment: "")
        }
    }
    
    var toSFSymbols: String {
        switch self {
        case .recommendations: "wand.and.stars"
        case .explore: "popcorn"
        }
    }
}

