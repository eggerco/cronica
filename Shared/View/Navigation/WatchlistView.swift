//
//  WatchListView.swift
//  Cronica
//
//  Created by Alexandre Madeira on 15/01/22.
//

import SwiftUI

struct WatchlistView: View {
    static let tag: Screens? = .watchlist
    @State private var showListSelection = false
    @State private var navigationTitle = NSLocalizedString("Watchlist", comment: "")
    @State private var navigationDisplayTitle = String()
    @State private var selectedList: CustomList?
    @State private var showPopup = false
    @State private var popupType: ActionPopupItems?
    
    @Environment(\.managedObjectContext) var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CustomList.title, ascending: true)],
        animation: .default)
    private var lists: FetchedResults<CustomList>
    var body: some View {
        VStack {
            if selectedList != nil {
                CustomWatchlist(selectedList: $selectedList, showPopup: $showPopup, popupType: $popupType)
            } else {
#if os(tvOS)
                DefaultWatchlist(showPopup: $showPopup, popupType: $popupType, selectedList: $selectedList)
#else
                DefaultWatchlist(showPopup: $showPopup, popupType: $popupType)
#endif
            }
        }
        .actionPopup(isShowing: $showPopup, for: popupType)
#if !os(tvOS)
        .navigationTitle(navigationTitle)
#endif
        .onChange(of: selectedList) { _, newValue in
            if let newValue {
                navigationTitle = newValue.itemTitle
            } else {
                navigationTitle = NSLocalizedString("Watchlist", comment: "")
            }
        }
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.automatic, for: .navigationBar)
#elseif os(tvOS)
        .ignoresSafeArea(.all, edges: .horizontal)
#endif
        .navigationDestination(for: WatchlistItem.self) { item in
            ItemContentDetails(title: item.itemTitle, id: item.itemId, type: item.itemMedia)
#if os(tvOS)
                .ignoresSafeArea(.all, edges: .horizontal)
#endif
        }
        .navigationDestination(for: ItemContent.self) { item in
            ItemContentDetails(title: item.itemTitle, id: item.id, type: item.itemContentMedia)
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
            let title = item.map { (key, _) in key }.first
            let items = item.map { (_, value) in value }.first
            if let title, let items {
                ItemContentSectionDetails(title: title, items: items)
            }
        }
        .navigationDestination(for: [Person].self) { items in
            DetailedPeopleList(items: items)
        }
        .navigationDestination(for: ProductionCompany.self) { item in
            CompanyDetails(company: item)
        }
        .navigationDestination(for: [ProductionCompany].self) { item in
            CompaniesListView(companies: item)
        }
        .sheet(isPresented: $showListSelection) {
            SelectListView(selectedList: $selectedList,
                           navigationTitle: $navigationTitle,
                           showListSelection: $showListSelection)
#if os(macOS)
            .frame(width: 480, height: 400, alignment: .center)
#endif
        }
        .toolbar {
            // Acts like a navigationTitle
#if os(iOS)
            ToolbarItem(placement: .principal) {
                WatchlistTitle(navigationTitle: $navigationTitle, showListSelection: $showListSelection)
            }
#elseif os(macOS) || os(visionOS)
            ToolbarItem(placement: .navigation) {
                WatchlistTitle(navigationTitle: $navigationTitle, showListSelection: $showListSelection)
                    .buttonStyle(.bordered)
            }
#endif
        }
    }
}

#Preview {
    WatchlistView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
