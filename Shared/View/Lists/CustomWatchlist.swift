//
//  CustomWatchlist.swift
//  Cronica
//
//  Created by Alexandre Madeira on 14/02/23.
//

import SwiftUI

struct CustomWatchlist: View {
    @Binding var selectedList: CustomList?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var filteredItems = [WatchlistItem]()
    @State private var query = ""
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
    @State private var showBatchEdit = false
#if os(tvOS)
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \CustomList.isPin, ascending: false),
                                    NSSortDescriptor(keyPath: \CustomList.title, ascending: true)],
                  animation: .default) private var lists: FetchedResults<CustomList>
#endif
    private var sortedItems: [WatchlistItem] {
        guard let list = selectedList else { return [] }
        return list.sortedItems(by: sortOrder)
    }
    private var smartFiltersItems: [WatchlistItem] {
        let base: [WatchlistItem]
        switch selectedOrder {
        case .released:
            base = sortedItems.filter { $0.isReleased }
        case .production:
            base = sortedItems.filter { $0.isInProduction || $0.isUpcoming }
        case .watching:
            base = sortedItems.filter { $0.isCurrentlyWatching }
        case .watched:
            base = sortedItems.filter { $0.isWatched }
        case .favorites:
            base = sortedItems.filter { $0.isFavorite }
        case .pin:
            base = sortedItems.filter { $0.isPin }
        case .archive:
            base = sortedItems.filter { $0.isArchive }
        case .notWatched:
            base = sortedItems.filter { !$0.isCurrentlyWatching && !$0.isWatched && $0.isReleased }
        }
        return mediaTypeFilter.apply(to: base)
    }
    private var searchResultItems: [WatchlistItem] {
        mediaTypeFilter.apply(to: filteredItems)
    }
    private var mediaTypeItems: [WatchlistItem] {
        mediaTypeFilter.apply(to: sortedItems)
    }
    private var displayedItems: [WatchlistItem] {
        showAllItems ? mediaTypeItems : smartFiltersItems
    }
    private var listSectionTitle: String {
        if showAllItems {
            return mediaTypeFilter.localizableTitle
        }
        return selectedOrder.title
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
                            EmptyListView(listTitle: selectedList?.itemTitle)
                        } else if displayedItems.isEmpty {
                            EmptyListView(listTitle: selectedList?.itemTitle)
                        } else {
                            switch settings.watchlistStyle {
                            case .list:
                                WatchListSection(items: displayedItems,
                                                 title: listSectionTitle,
                                                 emptyFilter: showAllItems ? nil : selectedOrder,
                                                 showPopup: $showPopup, popupType: $popupType)
                            case .card:
                                WatchlistCardSection(items: displayedItems,
                                                     title: listSectionTitle,
                                                     emptyFilter: showAllItems ? nil : selectedOrder,
                                                     showPopup: $showPopup,
                                                     popupType: $popupType)
                            case .poster:
                                WatchlistPosterSection(items: displayedItems,
                                                       title: listSectionTitle,
                                                       emptyFilter: showAllItems ? nil : selectedOrder,
                                                       showPopup: $showPopup, popupType: $popupType)
                            }
                        }
                    }
                }
                #else
                if items.isEmpty {
                    EmptyListView(listTitle: selectedList?.itemTitle)
                } else {
                    if !filteredItems.isEmpty {
                        switch settings.watchlistStyle {
                        case .list:
                            WatchListSection(items: searchResultItems,
                                             title: String(localized: "Search results"),
                                             showPopup: $showPopup, popupType: $popupType)
                        case .card:
                            WatchlistCardSection(items: searchResultItems,
                                                 title: String(localized: "Search results"), showPopup: $showPopup, popupType: $popupType)
                        case .poster:
                            WatchlistPosterSection(items: searchResultItems,
                                                   title: String(localized: "Search results"), showPopup: $showPopup, popupType: $popupType)
                        }
                        
                    } else if !query.isEmpty && filteredItems.isEmpty && !isSearching  {
                        noResults
                    } else {
                        switch settings.watchlistStyle {
                        case .list:
                            WatchListSection(items: displayedItems,
                                             title: listSectionTitle,
                                             emptyFilter: showAllItems ? nil : selectedOrder,
                                             showPopup: $showPopup, popupType: $popupType)
                        case .card:
                            WatchlistCardSection(items: displayedItems,
                                                 title: listSectionTitle,
                                                 emptyFilter: showAllItems ? nil : selectedOrder,
                                                 showPopup: $showPopup,
                                                 popupType: $popupType)
                        case .poster:
                            WatchlistPosterSection(items: displayedItems,
                                                   title: listSectionTitle,
                                                   emptyFilter: showAllItems ? nil : selectedOrder,
                                                   showPopup: $showPopup, popupType: $popupType)
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
                HStack {
                    if !(selectedList?.itemsArray.isEmpty ?? true) {
                        Button("Select", systemImage: "checkmark.circle") {
                            showBatchEdit = true
                        }
                    }
                    filterButton
                }
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
                    placement: horizontalSizeClass == .regular ? .automatic : .navigationBarDrawer(displayMode: .always),
                    prompt: "Search \(selectedList?.itemTitle ?? "List")")
        .safeAreaInset(edge: .top, spacing: 0) {
            if selectedList?.itemsArray.isEmpty == false {
                mediaTypePicker
            }
        }
#elseif os(macOS)
        .searchable(text: $query, placement: .toolbar, prompt: "Search \(selectedList?.itemTitle ?? "List")")
        .safeAreaInset(edge: .top, spacing: 0) {
            if selectedList?.itemsArray.isEmpty == false {
                mediaTypePicker
            }
        }
#elseif os(visionOS)
        .safeAreaInset(edge: .top, spacing: 0) {
            if selectedList?.itemsArray.isEmpty == false {
                mediaTypePicker
            }
        }
#endif
        .disableAutocorrection(true)
        .task(id: query) {
            isSearching = true
            try? await Task.sleep(nanoseconds: 300_000_000)
            if !filteredItems.isEmpty { filteredItems.removeAll() }
            if let items = selectedList?.itemsArray {
                filteredItems.append(contentsOf: items.filter { $0.title?.localizedStandardContains(query) == true })
            }
            isSearching = false
        }
        .sheet(isPresented: $showFilters) {
            ListFilterView(showView: $showFilters,
                           sortOrder: $sortOrder,
                           filter: $selectedOrder,
                           showAllItems: $showAllItems)
        }
        .sheet(isPresented: $showBatchEdit) {
            WatchlistBatchEditView(items: displayedItems, isPresented: $showBatchEdit)
        }
    }

    private var mediaTypePicker: some View {
        Picker("Media Type", selection: $mediaTypeFilter) {
            ForEach(MediaTypeFilters.allCases) { item in
                Text(item.localizableTitle).tag(item)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .padding(.horizontal)
        .padding(.vertical, 8)
        .sensoryFeedback(.selection, trigger: mediaTypeFilter)
        .accessibilityIdentifier("Custom List Media Type Filter")
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
            Divider()
            Picker("Media Type", selection: $mediaTypeFilter) {
                ForEach(MediaTypeFilters.allCases) { sort in
                    Text(sort.localizableTitle).tag(sort)
                }
            }
            .pickerStyle(.menu)
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
