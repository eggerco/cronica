//
//  CustomWatchlist.swift
//  Cronica
//
//  Created by Alexandre Madeira on 14/02/23.
//

import SwiftUI

struct CustomWatchlist: View {
    @Binding var selectedList: CustomList?
    @State private var filteredItems = [WatchlistItem]()
    @State private var query = ""
    @State private var scope: WatchlistSearchScope = .noScope
#if os(iOS)
    @Environment(\.editMode) private var editMode
#endif
    @State private var isSearching = false
    @StateObject private var settings = SettingsStore.shared
    @State private var showFilter = false
    @AppStorage("customListShowAllItems") private var showAllItems = true
    @AppStorage("customListMediaTypeFilter") private var mediaTypeFilter: MediaTypeFilters = .showAll
    @AppStorage("customListSmartFilter") private var selectedOrder: SmartFiltersTypes = .released
    @Binding var showPopup: Bool
    @Binding var popupType: ActionPopupItems?
    @AppStorage("customListSortOrder") private var sortOrder: WatchlistSortOrder = .titleAsc
    @State private var showFilters = false
#if os(tvOS)
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \CustomList.title, ascending: true)],
                  animation: .default) private var lists: FetchedResults<CustomList>
#endif
    private var sortedItems: [WatchlistItem] {
        guard let items = selectedList?.itemsArray else { return [] }
        switch sortOrder {
        case .titleAsc:
            return items.sorted { $0.itemTitle < $1.itemTitle }
        case .titleDesc:
            return items.sorted { $0.itemTitle > $1.itemTitle }
        case .ratingAsc:
            return items.sorted { $0.userRating < $1.userRating }
        case .ratingDesc:
            return items.sorted { $0.userRating > $1.userRating }
        case .dateAsc:
            return items.sorted { $0.itemSortDate < $1.itemSortDate }
        case .dateDesc:
            return items.sorted { $0.itemSortDate > $1.itemSortDate }
        }
    }
    private var smartFiltersItems: [WatchlistItem] {
        switch selectedOrder {
        case .released:
            return sortedItems.filter { $0.isReleased }
        case .production:
            return sortedItems.filter { $0.isInProduction || $0.isUpcoming }
        case .watching:
            return sortedItems.filter { $0.isCurrentlyWatching }
        case .watched:
            return sortedItems.filter { $0.isWatched }
        case .favorites:
            return sortedItems.filter { $0.isFavorite }
        case .pin:
            return sortedItems.filter { $0.isPin }
        case .archive:
            return sortedItems.filter { $0.isArchive }
        case .notWatched:
            return sortedItems.filter { !$0.isCurrentlyWatching && !$0.isWatched && $0.isReleased }
        }
    }
    private var scopeFiltersItems: [WatchlistItem] {
        switch scope {
        case .noScope:
            return filteredItems
        case .movies:
            return filteredItems.filter { $0.isMovie }
        case .shows:
            return filteredItems.filter { $0.isTvShow }
        }
    }
    private var mediaTypeItems: [WatchlistItem] {
        switch mediaTypeFilter {
        case .showAll:
            return sortedItems
        case .movies:
            return sortedItems.filter { $0.isMovie }
        case .tvShows:
            return sortedItems.filter { $0.isTvShow }
        }
    }
    var body: some View {
        VStack {
            if let items = selectedList?.itemsArray {
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
                        if items.isEmpty {
                            EmptyListView()
                        } else {
                            if !filteredItems.isEmpty {
                                switch settings.watchlistStyle {
                                case .list:
                                    WatchListSection(items: scopeFiltersItems,
                                                     title: NSLocalizedString("Search results", comment: ""),
                                                     showPopup: $showPopup, popupType: $popupType)
                                case .card:
                                    WatchlistCardSection(items: scopeFiltersItems,
                                                         title: NSLocalizedString("Search results", comment: ""), showPopup: $showPopup, popupType: $popupType)
                                case .poster:
                                    WatchlistPosterSection(items: scopeFiltersItems,
                                                           title: NSLocalizedString("Search results", comment: ""), showPopup: $showPopup, popupType: $popupType)
                                }
                                
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
                                                         title: selectedOrder.title,
                                                         showPopup: $showPopup, popupType: $popupType)
                                    case .card:
                                        WatchlistCardSection(items: smartFiltersItems,
                                                             title: selectedOrder.title,
                                                             showPopup: $showPopup,
                                                             popupType: $popupType)
                                    case .poster:
                                        WatchlistPosterSection(items: smartFiltersItems,
                                                               title: selectedOrder.title,
                                                               showPopup: $showPopup, popupType: $popupType)
                                    }
                                }
                            }
                        }
                    }
                }
                #else
                if items.isEmpty {
                    EmptyListView()
                } else {
                    if !filteredItems.isEmpty {
                        switch settings.watchlistStyle {
                        case .list:
                            WatchListSection(items: scopeFiltersItems,
                                             title: NSLocalizedString("Search results", comment: ""),
                                             showPopup: $showPopup, popupType: $popupType)
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
                                                 title: selectedOrder.title,
                                                 showPopup: $showPopup, popupType: $popupType)
                            case .card:
                                WatchlistCardSection(items: smartFiltersItems,
                                                     title: selectedOrder.title,
                                                     showPopup: $showPopup,
                                                     popupType: $popupType)
                            case .poster:
                                WatchlistPosterSection(items: smartFiltersItems,
                                                       title: selectedOrder.title,
                                                       showPopup: $showPopup, popupType: $popupType)
                            }
                        }
                    }
                }
                #endif
            }
        }
        .toolbar {
#if !os(tvOS)
#if os(iOS) || os(visionOS)
            ToolbarItem(placement: .navigationBarLeading) {
                styleButton
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                filterButton
            }
#elseif os(macOS)
            filterButton
#else
            filterButton
#endif
#endif
        }
#if os(iOS)
        .searchable(text: $query,
                    placement: UIDevice.isIPad ? .automatic : .navigationBarDrawer(displayMode: .always),
                    prompt: "Search \(selectedList?.itemTitle ?? "List")")
        .searchScopes($scope) {
            ForEach(WatchlistSearchScope.allCases) { scope in
                Text(scope.localizableTitle).tag(scope)
            }
        }
#elseif os(macOS)
        .searchable(text: $query, placement: .toolbar, prompt: "Search \(selectedList?.itemTitle ?? "List")")
#endif
        .disableAutocorrection(true)
        .task(id: query) {
            isSearching = true
            try? await Task.sleep(nanoseconds: 300_000_000)
            if !filteredItems.isEmpty { filteredItems.removeAll() }
            if let items = selectedList?.itemsArray {
                filteredItems.append(contentsOf: items.filter { ($0.title?.localizedStandardContains(query))! as Bool })
            }
            isSearching = false
        }
        .sheet(isPresented: $showFilters) {
            ListFilterView(showView: $showFilters,
                           sortOrder: $sortOrder,
                           filter: $selectedOrder,
                           mediaFilter: $mediaTypeFilter,
                           showAllItems: $showAllItems)
        }
    }
    
    private var styleButton: some View {
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
    }
    
    private var filterButton: some View {
#if os(tvOS) || os(macOS)
        Menu {
            Toggle("Show All", isOn: $showAllItems)
            Picker("Media Type", selection: $mediaTypeFilter) {
                ForEach(MediaTypeFilters.allCases) { sort in
                    Text(sort.localizableTitle).tag(sort)
                }
            }
            .pickerStyle(.menu)
            .disabled(!showAllItems)
            Picker("Smart Filters", selection: $selectedOrder) {
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
#else
        Button("Filters",
               systemImage: "line.3.horizontal.decrease.circle") {
            showFilters = true
        }
#endif
    }
    
    @ViewBuilder
    private var noResults: some View {
        SearchContentUnavailableView(query: query)
    }
}

struct EmptyListView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Your Watchlist is empty", systemImage: "rectangle.on.rectangle")
        } description: {
            Text("Add movies and shows from Discover or Search to build your list.")
        }
        .padding()
    }
}

struct SearchContentUnavailableView: View {
    let query: String
    var body: some View {
        ContentUnavailableView.search(text: query)
    }
}
