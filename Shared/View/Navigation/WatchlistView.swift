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
    @State private var navigationTitle = String(localized: "Watchlist")
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
        .accessibilityIdentifier("Watchlist View")
#if !os(tvOS)
        .navigationTitle(navigationTitle)
#endif
        .onChange(of: selectedList) { _, newValue in
            if let newValue {
                navigationTitle = newValue.itemTitle
            } else {
                navigationTitle = String(localized: "Watchlist")
            }
        }
#if os(iOS) || os(visionOS)
        .onReceive(NotificationCenter.default.publisher(for: .cronicaTabDidReselect)) { notification in
            guard let tab = notification.object as? Screens, tab == .watchlist else { return }
            selectedList = nil
            navigationTitle = String(localized: "Watchlist")
        }
#endif
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#elseif os(tvOS)
        .ignoresSafeArea(.all, edges: .horizontal)
#endif
        .cronicaWatchlistNavigationDestinations()
        .sheet(isPresented: $showListSelection) {
            SelectListView(selectedList: $selectedList,
                           navigationTitle: $navigationTitle,
                           showListSelection: $showListSelection)
#if os(macOS)
            .frame(width: 480, height: 400, alignment: .center)
#else
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .appTheme()
            .appTint()
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
