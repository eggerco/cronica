//
//  SideBarView.swift
//  Cronica
//
//  Created by Alexandre Madeira on 28/04/22.
//
import SwiftUI

#if os(macOS)
struct SideBarView: View {
    @SceneStorage("selectedView") private var selectedView: Screens = .home
    @StateObject private var viewModel = SearchViewModel()
    @State private var selectedSearchItem: ItemContent?
	@State private var showNotifications = false
    private let persistence = PersistenceController.shared
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedView) {
                NavigationLink(value: Screens.home) {
                    Label("Home", systemImage: "house")
                }.tag(HomeView.tag)
                
                NavigationLink(value: Screens.explore) {
                    Label("Explore", systemImage: "popcorn")
                }.tag(ExploreView.tag)
                
                NavigationLink(value: Screens.watchlist) {
                    Label("Watchlist", systemImage: "square.stack")
                }.tag(WatchlistView.tag)
                
                NavigationLink(value: Screens.search) {
                    Label("Search", systemImage: "magnifyingglass")
                }.tag(SearchView.tag)
            }
            .listStyle(.sidebar)
        } detail: {
            switch selectedView {
            case .home:
                NavigationStack {
                    HomeView()
                        .environment(\.managedObjectContext, persistence.container.viewContext)
                }
            case .explore:
                NavigationStack { ExploreView() }
            case .watchlist:
                NavigationStack {
                    WatchlistView()
                        .environment(\.managedObjectContext, persistence.container.viewContext)
                }
            case .search:
                NavigationStack { SearchView(shouldFocusOnSearchField: .constant(false)) }
            default:
                NavigationStack { HomeView().environment(\.managedObjectContext, persistence.container.viewContext) }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $showNotifications) {
            NavigationStack {
                NotificationListView(showNotification: $showNotifications)
                    .cronicaWatchlistNavigationDestinations()
            }
        }
    }
}

#Preview {
    SideBarView()
}
#endif
