//
//  WatchlistView.swift
//  Cronica Watch App
//
//  Created by Alexandre Madeira on 13/08/22.
//

import SwiftUI

struct WatchlistView: View {
    static let tag: Screens? = .watchlist
    @Environment(\.managedObjectContext) var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WatchlistItem.title, ascending: true)],
        animation: .default) private var items: FetchedResults<WatchlistItem>
    @AppStorage("selectedOrder") private var selectedOrder: SmartFiltersTypes = .released
	@AppStorage("defaultWatchlistSortOrder") private var sortOrder: WatchlistSortOrder = .titleAsc
    @State private var selectedList: SmartFiltersTypes?
    @State private var selectedCustomList: CustomList?
    @State private var query = ""
    @State private var showPicker = false
    @StateObject private var settings = SettingsStore.shared
    var body: some View {
        NavigationStack {
            VStack {
                if selectedList != nil {
                    defaultList
                } else if selectedCustomList != nil {
                    customList
                } else {
                    EmptyListView()
                }
            }
            .navigationTitle("Watchlist")
            .navigationBarTitleDisplayMode(.inline)
            .disableAutocorrection(true)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sort List", systemImage: "line.3.horizontal.decrease") {
                        withAnimation { showPicker = true }
                    }
                    .labelStyle(.iconOnly)
                    .tint(settings.appTheme.color)
                }
            }
            .navigationDestination(for: WatchlistItem.self) { item in
                ItemContentView(id: item.itemId,
                                title: item.itemTitle,
                                type: item.itemMedia,
                                image: item.backCompatibleCardImage)
            }
            .navigationDestination(for: ItemContent.self) { item in
				ItemContentView(id: item.id,
								title: item.itemTitle,
								type: item.itemContentMedia,
								image: item.cardImageMedium)
            }
			.navigationDestination(for: SearchItemContent.self) { item in
				if item.media == .person {
                    PersonDetailsView(name: item.itemTitle, id: item.id)
				} else {
					ItemContentView(id: item.id,
									title: item.itemTitle,
									type: item.itemContentMedia,
									image: item.cardImageMedium)
				}
			}
            .sheet(isPresented: $showPicker) {
                WatchlistSelectorView(showView: $showPicker,
                                      selectedList: $selectedList,
                                      selectedCustomList: $selectedCustomList,
                                      sortOrder: $sortOrder)
            }
            .onAppear {
                if selectedList == nil && selectedCustomList == nil {
                    selectedList = selectedOrder
                }
            }
            .onChange(of: selectedList) { _, newValue in
                guard let newValue else { return }
                selectedOrder = newValue
            }
        }
    }
    
    @ViewBuilder
    private var defaultList: some View {
        if items.isEmpty {
            EmptyListView()
        } else {
			DefaultListView(selectedOrder: $selectedList, sortOrder: $sortOrder)
        }
    }
    
    @ViewBuilder
    private var customList: some View {
        if items.isEmpty {
            EmptyListView()
        } else {
			CustomListView(list: $selectedCustomList, sortOrder: $sortOrder)
        }
    }
}

#Preview {
    WatchlistView()
}
