//
//  TabBarView.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 01/05/22.
//

import SwiftUI
import CronicaCore
#if !os(macOS)
extension Notification.Name {
    /// Posted when the user taps the already-selected tab bar item. Object is a `Screens` value.
    static let cronicaTabDidReselect = Notification.Name("cronicaTabDidReselect")
}

/// A TabBar for switching views, only used on iPhone.
struct TabBarView: View {
#if os(iOS)
    @ObservedObject private var quickActions = QuickActionCoordinator.shared
    @Environment(\.scenePhase) private var scenePhase
#endif
    @AppStorage("lastTabSelected") private var tabSelection: Screens?
    var persistence = PersistenceController.shared

    private static let tabBarTabs: [Screens] = [.home, .explore, .watchlist, .search]

    private var selectedTab: Binding<Screens> {
        .init {
            tabSelection ?? .home
        } set: { newValue in
            if newValue == tabSelection {
                handleTabReselect(newValue)
            }
            tabSelection = newValue
        }
    }

    @State private var homePath: NavigationPath = .init()
    @State private var explorePath: NavigationPath = .init()
    @State private var watchlistPath: NavigationPath = .init()
    @State private var searchPath: NavigationPath = .init()
    @State private var shouldOpenOnSearchField = false
#if os(iOS)
    @State private var showQuickActionPopup = false
    @State private var quickActionPopupType: ActionPopupItems?
    @State private var showNoUpNextAlert = false
#endif

    var body: some View {
#if os(iOS)
        Group {
            if #available(iOS 18, *), UIDevice.current.userInterfaceIdiom == .pad {
                newTabView
            } else {
                details
            }
        }
        .task { await bootstrapNavigationWhenReady(applyLaunchPreference: true) }
        .onChange(of: quickActions.pending) { _, pending in
            guard pending != nil else { return }
            Task { await bootstrapNavigationWhenReady(applyLaunchPreference: false) }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await bootstrapNavigationWhenReady(applyLaunchPreference: false) }
        }
        .onChange(of: quickActions.feedback) { _, feedback in
            handleQuickActionFeedback(feedback)
        }
        .actionPopup(isShowing: $showQuickActionPopup, for: quickActionPopupType)
        .alert(
            String(localized: "Nothing Up Next"),
            isPresented: $showNoUpNextAlert
        ) {
            Button("OK", role: .cancel) {
                quickActions.clearFeedback()
            }
        } message: {
            Text(String(localized: "You don't have any episodes up next."))
        }
        .appTint()
        .appTheme()
#else
        details
            .onAppear { applyPreferredLaunchScreen() }
            .appTint()
            .appTheme()
#endif
    }

#if os(iOS)
    private func bootstrapNavigationWhenReady(applyLaunchPreference: Bool) async {
        let maxAttempts = UITestingConfiguration.isUITesting ? 40 : 6
        let retryDelay: Duration = UITestingConfiguration.isUITesting
            ? .milliseconds(100)
            : .milliseconds(50)

        for attempt in 0..<maxAttempts {
            QuickActionManager.applyUITestLaunchActionIfNeeded()
            if let action = quickActions.consumePending() {
                applyPendingNavigation(action)
                return
            }
            if attempt < maxAttempts - 1 {
                try? await Task.sleep(for: retryDelay)
            }
        }

        if applyLaunchPreference {
            applyPreferredLaunchScreen()
        }
    }

    private func handleQuickActionFeedback(_ feedback: QuickActionFeedback?) {
        guard let feedback else { return }
        switch feedback {
        case .markedEpisodeWatched:
            quickActionPopupType = .markedEpisodeWatched
            showQuickActionPopup = true
        case .noUpNext:
            showNoUpNextAlert = true
        }
        quickActions.clearFeedback()
    }
#endif

    private func applyPreferredLaunchScreen() {
        let settings = SettingsStore.shared
        if settings.isPreferredLaunchScreenEnabled {
            tabSelection = settings.preferredLaunchScreen
        }
    }

    private func applyPendingNavigation(_ action: PendingAppNavigation) {
        QuickActionDebug.log("apply \(action.rawValue)")

        switch action {
        case .search:
            tabSelection = .search
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(150))
                shouldOpenOnSearchField = true
            }
        case .watchlist:
            tabSelection = .watchlist
#if canImport(AppIntents) && !os(watchOS) && !os(tvOS)
            Task { await SiriIntentDonation.donateOpenedWatchlist() }
#endif
        case .upNext:
            tabSelection = .home
#if canImport(AppIntents) && !os(watchOS) && !os(tvOS)
            Task { await SiriIntentDonation.donateOpenedUpNext() }
#endif
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(150))
                homePath.append(AppNavigationRoute.upNextList)
            }
        case .markUpNextEpisode:
#if os(iOS)
            Task { await QuickActionManager.performMarkUpNextEpisodeWatched() }
#endif
        }
    }

    private func handleTabReselect(_ tab: Screens) {
        switch tab {
        case .home:
            if !homePath.isEmpty {
                homePath = NavigationPath()
            }
        case .explore:
            if !explorePath.isEmpty {
                explorePath = NavigationPath()
            }
        case .watchlist:
            if !watchlistPath.isEmpty {
                watchlistPath = NavigationPath()
            }
        case .search:
            if !searchPath.isEmpty {
                searchPath = NavigationPath()
            } else {
                shouldOpenOnSearchField = true
            }
        default:
            return
        }

        NotificationCenter.default.post(name: .cronicaTabDidReselect, object: tab)
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

            NavigationStack { SearchView(shouldFocusOnSearchField: .constant(false)) }
                .tabItem { Image(systemName: "magnifyingglass").accessibilityLabel("Search") }

            SettingsView()
                .tabItem { Image(systemName: "gearshape").accessibilityLabel("Settings") }
        }
        .ignoresSafeArea(.all, edges: .horizontal)
    }
#endif

#if os(iOS)
    @available(iOS 18, *)
    private var newTabView: some View {
        TabView(selection: selectedTab) {
            Tab("Home", systemImage: "house", value: Screens.home) {
                NavigationStack(path: $homePath) {
                    HomeView()
                }
            }

            Tab("Discover", systemImage: "popcorn", value: Screens.explore) {
                NavigationStack(path: $explorePath) {
                    ExploreView()
                }
            }

            Tab("Watchlist", systemImage: "rectangle.on.rectangle", value: Screens.watchlist) {
                NavigationStack(path: $watchlistPath) {
                    WatchlistView()
                        .environment(\.managedObjectContext, persistence.container.viewContext)
                }
            }

            Tab("Search", systemImage: "magnifyingglass", value: Screens.search, role: .search) {
                NavigationStack(path: $searchPath) {
                    SearchView(shouldFocusOnSearchField: $shouldOpenOnSearchField)
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .background {
            TabBarReselectDetector(tabs: Self.tabBarTabs, onReselect: handleTabReselect)
        }
        .appTheme()
        .appTint()
    }
#endif

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
