//
//  DefaultWatchlist.swift
//  Cronica
//
//  Created by Alexandre Madeira on 14/02/23.
//

import SwiftUI

struct DefaultWatchlist: View {
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WatchlistItem.title, ascending: true)],
        animation: .default) private var items: FetchedResults<WatchlistItem>
    @State private var filteredItems = [WatchlistItem]()
    @State private var query = ""
    @AppStorage("selectedOrder") private var smartFilter: SmartFiltersTypes = .released
    @State private var scope: WatchlistSearchScope = .noScope
    @State private var isSearching = false
    @StateObject private var settings = SettingsStore.shared
    @AppStorage("watchlistShowAllItems") private var showAllItems = false
    @AppStorage("watchlistMediaTypeFilter") private var mediaTypeFilter: MediaTypeFilters = .showAll
    @Binding var showPopup: Bool
    @Binding var popupType: ActionPopupItems?
    @AppStorage("defaultWatchlistSortOrder") private var sortOrder: WatchlistSortOrder = .titleAsc
    @State private var showFilters = false
    private var sortedItems: [WatchlistItem] {
        switch sortOrder {
        case .titleAsc:
            items.sorted { $0.itemTitle < $1.itemTitle }
        case .titleDesc:
            items.sorted { $0.itemTitle > $1.itemTitle }
        case .ratingAsc:
            items.sorted { $0.userRating < $1.userRating }
        case .ratingDesc:
            items.sorted { $0.userRating > $1.userRating }
        case .dateAsc:
            items.sorted { $0.itemSortDate < $1.itemSortDate }
        case .dateDesc:
            items.sorted { $0.itemSortDate > $1.itemSortDate }
        }
    }
    private var smartFiltersItems: [WatchlistItem] {
        switch smartFilter {
        case .released:
            sortedItems.filter { $0.isReleased }
        case .production:
            sortedItems.filter { $0.isInProduction || $0.isUpcoming }
        case .watching:
            sortedItems.filter { $0.isCurrentlyWatching }
        case .watched:
            sortedItems.filter { $0.isWatched }
        case .favorites:
            sortedItems.filter { $0.isFavorite }
        case .pin:
            sortedItems.filter { $0.isPin }
        case .archive:
            sortedItems.filter { $0.isArchive }
        case .notWatched:
            sortedItems.filter { !$0.isCurrentlyWatching && !$0.isWatched && $0.isReleased }
        }
    }
    private var scopeFiltersItems: [WatchlistItem] {
        switch scope {
        case .noScope: filteredItems
        case .movies: filteredItems.filter { $0.isMovie }
        case .shows: filteredItems.filter { $0.isTvShow }
        }
    }
    private var mediaTypeItems: [WatchlistItem] {
        switch mediaTypeFilter {
        case .showAll: sortedItems
        case .movies: sortedItems.filter { $0.isMovie }
        case .tvShows: sortedItems.filter { $0.isTvShow }
        }
    }
#if os(tvOS)
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \CustomList.title, ascending: true)],
                  animation: .default) private var lists: FetchedResults<CustomList>
    @Binding var selectedList: CustomList?
#endif
    var body: some View {
        VStack {
#if os(tvOS)
            ScrollView {
                LazyVStack {
                    if !items.isEmpty {
                        HStack {
                            Menu {
                                if lists.isEmpty {
                                    Button("Please, use the iPhone app to create new lists.") { }
                                }
                                if selectedList == nil {
                                    Button {
                                        
                                    } label: {
                                        Label("Watchlist", systemImage: "checkmark")
                                    }
                                } else {
                                    Button {
                                        selectedList = nil
                                    } label: {
                                        Text("Watchlist")
                                    }
                                }
                                ForEach(lists) { list in
                                    Button {
                                        selectedList = list
                                    } label: {
                                        if selectedList == list {
                                            Label(list.itemTitle, systemImage: "checkmark")
                                        } else {
                                            Text(list.itemTitle)
                                        }
                                    }
                                }
                            } label: {
                                Label("Watchlist", systemImage: "rectangle.on.rectangle.angled")
                            }
                            .labelStyle(.iconOnly)
                            Spacer()
                            filterButton
                        }
                        .padding(.horizontal, 64)
                    }
                    if smartFiltersItems.isEmpty {
                        empty
                    } else {
                        switch settings.watchlistStyle {
                        case .list:
                            WatchlistCardSection(items: smartFiltersItems,
                                                 title: String(), showPopup: $showPopup, popupType: $popupType)
                        case .card:
                            WatchlistCardSection(items: smartFiltersItems,
                                                 title: String(), showPopup: $showPopup, popupType: $popupType)
                        case .poster:
                            WatchlistPosterSection(items: smartFiltersItems,
                                                   title: String(), showPopup: $showPopup, popupType: $popupType)
                        }
                        
                    }
                }
            }
#else
            if items.isEmpty {
                if scope != .noScope {
                    empty
                } else {
                    empty
                }
            } else {
                if !filteredItems.isEmpty {
                    switch settings.watchlistStyle {
                    case .list:
                        WatchListSection(items: scopeFiltersItems,
                                         title: NSLocalizedString("Search results", comment: ""), showPopup: $showPopup, popupType: $popupType)
                    case .card:
                        WatchlistCardSection(items: scopeFiltersItems,
                                             title: NSLocalizedString("Search results", comment: ""), showPopup: $showPopup, popupType: $popupType)
                    case .poster:
                        WatchlistPosterSection(items: scopeFiltersItems,
                                               title: NSLocalizedString("Search results", comment: ""), showPopup: $showPopup, popupType: $popupType)
                    }
                    
                } else if !query.isEmpty && filteredItems.isEmpty && !isSearching  {
                    noResults
                } else {
                    if showAllItems {
                        switch settings.watchlistStyle {
                        case .list:
                            WatchListSection(items: mediaTypeItems,
                                             title: mediaTypeFilter.localizableTitle,
                                             showPopup: $showPopup, popupType: $popupType)
                        case .card:
                            WatchlistCardSection(items: mediaTypeItems,
                                                 title: mediaTypeFilter.localizableTitle, showPopup: $showPopup, popupType: $popupType)
                        case .poster:
                            WatchlistPosterSection(items: mediaTypeItems,
                                                   title: mediaTypeFilter.localizableTitle, showPopup: $showPopup, popupType: $popupType)
                        }
                    } else {
                        switch settings.watchlistStyle {
                        case .list:
                            WatchListSection(items: smartFiltersItems,
                                             title: smartFilter.title,
                                             emptyFilter: smartFilter,
                                             showPopup: $showPopup, popupType: $popupType)
                        case .card:
                            WatchlistCardSection(items: smartFiltersItems,
                                                 title: smartFilter.title,
                                                 emptyFilter: smartFilter,
                                                 showPopup: $showPopup,
                                                 popupType: $popupType)
                        case .poster:
                            WatchlistPosterSection(items: smartFiltersItems,
                                                   title: smartFilter.title,
                                                   emptyFilter: smartFilter,
                                                   showPopup: $showPopup, popupType: $popupType)
                        }
                    }
                }
            }
#endif
        }
        .toolbar {
#if os(iOS) || os(visionOS)
            ToolbarItem(placement: .navigationBarLeading) {
                styleButton
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button("Filters",
                           systemImage: "line.3.horizontal.decrease.circle") {
                        showFilters = true
                    }
                }
            }
#elseif os(macOS)
            filterButton
#endif
        }
#if os(iOS)
        .searchable(text: $query,
                    placement: horizontalSizeClass == .regular ? .automatic : .navigationBarDrawer(displayMode: .always),
                    prompt: "Search Watchlist")
        .safeAreaInset(edge: .top, spacing: 0) {
            if !query.isEmpty {
                Picker("Filter", selection: $scope) {
                    ForEach(WatchlistSearchScope.allCases) { item in
                        Text(item.localizableTitle).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding(.horizontal)
                .padding(.vertical, 8)
                .sensoryFeedback(.selection, trigger: scope)
            }
        }
#elseif os(macOS)
        .searchable(text: $query, placement: .toolbar)
#endif
        .disableAutocorrection(true)
        .task(id: query) {
            await search()
        }
        .sheet(isPresented: $showFilters) {
            ListFilterView(showView: $showFilters,
                           sortOrder: $sortOrder,
                           filter: $smartFilter,
                           mediaFilter: $mediaTypeFilter,
                           showAllItems: $showAllItems)
        }
    }
    
    private func search() async {
        do {
            isSearching = true
            try await Task.sleep(nanoseconds: 300_000_000)
            if !filteredItems.isEmpty { filteredItems.removeAll() }
            filteredItems.append(contentsOf: items.filter {
                ($0.itemTitle.localizedStandardContains(query)) as Bool
                || ($0.itemOriginalTitle.localizedStandardContains(query)) as Bool
            })
            isSearching = false
        } catch {
            if Task.isCancelled { return }
        }
    }
    
#if !os(iOS)
    private var filterButton: some View {
        Menu {
#if !os(tvOS)
            Toggle("Show All Items", isOn: $showAllItems)
            Picker("Media Filter", selection: $mediaTypeFilter) {
                ForEach(MediaTypeFilters.allCases) { sort in
                    Text(sort.localizableTitle).tag(sort)
                }
            }
#if os(macOS)
            .pickerStyle(.inline)
#else
            .pickerStyle(.menu)
#endif
            .disabled(!showAllItems)
            Divider()
#endif
            Picker("Smart Filters", selection: $smartFilter) {
                ForEach(SmartFiltersTypes.allCases) { sort in
                    Text(sort.title).tag(sort)
                }
            }
            .disabled(showAllItems)
#if os(macOS)
            .pickerStyle(.inline)
#elseif os(tvOS)
            .pickerStyle(.menu)
#endif
            Picker("Sort Order",
                   selection: $sortOrder) {
                ForEach(WatchlistSortOrder.allCases) { item in
                    Text(item.localizableName).tag(item)
                }
            }
#if os(iOS) || os(tvOS)
                   .pickerStyle(.menu)
#else
                   .pickerStyle(.inline)
#endif
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .accessibilityLabel("Sort List")
        }
        .buttonStyle(.bordered)
    }
#endif
    
    private var styleButton: some View {
#if os(macOS)
        Picker(selection: $settings.watchlistStyle) {
            ForEach(SectionDetailsPreferredStyle.allCases) { item in
                Text(item.title).tag(item)
            }
        } label: {
            Label("Display Style", systemImage: "circle.grid.2x2")
                .labelStyle(.iconOnly)
        }
#else
        Menu {
            Picker(selection: $settings.watchlistStyle) {
                ForEach(SectionDetailsPreferredStyle.allCases) { item in
                    Text(item.title).tag(item)
                }
            } label: {
                Label("Display Style", systemImage: "circle.grid.2x2")
            }
        } label: {
            Label("Display Style", systemImage: "circle.grid.2x2")
                .labelStyle(.iconOnly)
        }
#endif
    }
    
    @ViewBuilder
    private var empty: some View {
        EmptyListView(filter: showAllItems ? nil : smartFilter)
    }
    
    @ViewBuilder
    private var noResults: some View {
        SearchContentUnavailableView(query: query)
    }
}

#Preview {
#if os(tvOS)
    DefaultWatchlist(showPopup: .constant(false), popupType: .constant(nil), selectedList: .constant(nil))
#else
    DefaultWatchlist(showPopup: .constant(false), popupType: .constant(nil))
#endif
}
