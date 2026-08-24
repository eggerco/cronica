//
//  TabBarView.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 01/05/22.
//

import SwiftUI
#if !os(macOS)
/// A TabBar for switching views, only used on iPhone.
struct TabBarView: View {
    @AppStorage("lastTabSelected") private var tabSelection: Screens?
    var persistence = PersistenceController.shared
    private var selectedTab: Binding<Screens> {
        return .init {
            return tabSelection ?? .home
        } set: { newValue in
            if newValue == tabSelection {
                switch newValue {
                case .home:
                    if !homePath.isEmpty {
                        homePath = .init()
                    }
                case .explore:
                    if !explorePath.isEmpty {
                        explorePath = .init()
                    }
                case .watchlist:
                    if !watchlistPath.isEmpty {
                        watchlistPath = .init()
                    }
                case .search:
                    if !searchPath.isEmpty {
                        searchPath = .init()
                    } else {
                        shouldOpenOnSearchField = true
                    }
                default: return
                }
            }
            tabSelection = newValue
        }
    }
    @State private var homePath: NavigationPath = .init()
    @State private var explorePath: NavigationPath = .init()
    @State private var watchlistPath: NavigationPath = .init()
    @State private var searchPath: NavigationPath = .init()
    @State private var shouldOpenOnSearchField = false
    var body: some View {
#if os(iOS)
        Group {
            if #available(iOS 18, *) {
                newTabView
            } else {
                details
            }
        }
        .onAppear {
            let settings = SettingsStore.shared
            if settings.isPreferredLaunchScreenEnabled {
                tabSelection = settings.preferredLaunchScreen
            }
        }
        .appTint()
        .appTheme()
#else
        details
            .onAppear {
                let settings = SettingsStore.shared
                if settings.isPreferredLaunchScreenEnabled {
                    tabSelection = settings.preferredLaunchScreen
                }
            }
            .appTint()
            .appTheme()
#endif
    }
    
#if os(tvOS)
    private var details: some View {
        TabView {
            NavigationStack { HomeView() }
                .tag(HomeView.tag)
                .tabItem { Label("Home", systemImage: "house").labelStyle(.titleOnly) }
                .ignoresSafeArea(.all, edges: .horizontal)
            
            NavigationStack { ExploreView() }
                .tag(ExploreView.tag)
                .tabItem { Label("Explore", systemImage: "popcorn").labelStyle(.titleOnly) }
            
            NavigationStack {
                WatchlistView()
                    .environment(\.managedObjectContext, persistence.container.viewContext)
            }
            .tabItem { Label("Watchlist", systemImage: "square.stack").labelStyle(.titleOnly) }
            .tag(WatchlistView.tag)
            
            NavigationStack { SearchView() }
                .tabItem { Image(systemName: "magnifyingglass").accessibilityLabel("Search") }
            
            SettingsView()
                .tabItem { Image(systemName: "gearshape").accessibilityLabel("Settings") }
        }
        .ignoresSafeArea(.all, edges: .horizontal)
    }
#endif
    
    @available(iOS 18, *)
    private var newTabView: some View {
        TabView(selection: selectedTab) {
            Tab("Home", systemImage: "house", value: .home) {
                NavigationStack(path: $homePath) {
                    HomeView()
                }
            }
            
            Tab("Discover", systemImage: "popcorn", value: .explore) {
                NavigationStack(path: $explorePath) {
                    ExploreView()
                }
            }
            
            Tab("Watchlist", systemImage: "rectangle.on.rectangle", value: .watchlist) {
                NavigationStack(path: $watchlistPath) {
                    WatchlistView()
                        .environment(\.managedObjectContext, persistence.container.viewContext)
                }
            }
            
            Tab("Search", systemImage: "magnifyingglass", value: .search, role: .search) {
                NavigationStack(path: $searchPath) {
                    SearchView(shouldFocusOnSearchField: $shouldOpenOnSearchField)
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .appTheme()
        .appTint()
    }
    
#if os(iOS) || os(visionOS)
    private var details: some View {
        TabView(selection: selectedTab) {
            NavigationStack(path: $homePath) {
                HomeView()
            }
            .tag(Screens.home)
            .tabItem { Label("Home", systemImage: "house") }
            
            NavigationStack(path: $explorePath) {
                ExploreView()
            }
            .tag(Screens.explore)
            .tabItem { Label("Discover", systemImage: "popcorn") }
            
            NavigationStack(path: $watchlistPath) {
                WatchlistView()
                    .environment(\.managedObjectContext, persistence.container.viewContext)
            }
            .tabItem { Label("Watchlist", systemImage: "rectangle.on.rectangle") }
            .tag(Screens.watchlist)
            
            NavigationStack(path: $searchPath) {
                SearchView(shouldFocusOnSearchField: $shouldOpenOnSearchField)
            }
            .tag(Screens.search)
            .tabItem { Label("Search", systemImage: "magnifyingglass") }
        }
        .appTheme()
        .appTint()
    }
#endif
}

#Preview {
    TabBarView()
}
#endif
