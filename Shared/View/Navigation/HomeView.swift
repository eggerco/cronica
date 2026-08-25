//
//  HomeView.swift
//  Story
//
//  Created by Alexandre Madeira on 10/02/22.
//

import SwiftUI

struct HomeView: View {
    static let tag: Screens? = .home
#if os(tvOS) || os(macOS)
    @AppStorage("showOnboarding") private var displayOnboard = false
#else
    @AppStorage("showOnboarding") private var displayOnboard = true
#endif
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var homeSections = HomeSectionStore.shared
    @State private var showNotifications = false
    @State private var showPopup = false
    @State private var reloadHome = false
    @State private var showWhatsNew = false
    @State private var hasNotifications = false
    @State private var popupType: ActionPopupItems?
#if os(iOS)
    @AppStorage("launchCount") var launchCount: Int = 0
    @AppStorage("askedForReview") var askedForReview = false
    @State private var showReviewBanner = false
    @State private var showSettings = false
#endif
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
#if os(iOS)
                if showReviewBanner { CallToReviewAppView(showView: $showReviewBanner).unredacted() }
#endif
                ForEach(homeSections.visibleOrderedSections) { section in
                    homeSectionView(section)
                }
                AttributionView()
            }
        }
        .accessibilityIdentifier("Home View")
#if os(iOS)
        .refreshable {
            reloadHome = true
            viewModel.reload()
        }
        .onAppear {
            checkAskForReview()
        }
#endif
        .cronicaLoadingOverlay(!viewModel.isLoaded)
        .overlay {
            if viewModel.isLoaded && viewModel.trending.isEmpty && viewModel.sectionResults.isEmpty {
                ContentUnavailableView {
                    Label("Couldn't Load Home", systemImage: "wifi.exclamationmark")
                } description: {
#if os(iOS)
                    Text("Pull to refresh or try again.")
#else
                    Text("Check your connection and try again.")
#endif
                } actions: {
                    Button("Retry") { viewModel.reload() }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .actionPopup(isShowing: $showPopup, for: popupType)
#if os(tvOS)
        .ignoresSafeArea(.all, edges: .horizontal)
#endif
        .cronicaHomeNavigationDestinations(showNotifications: $showNotifications)
        .redacted(reason: !viewModel.isLoaded ? .placeholder : [] )
        .onAppear {
            checkVersion()
#if os(iOS) || os(macOS)
            Task {
                let notifications = await NotificationManager.shared.hasDeliveredItems()
                hasNotifications = notifications
            }
#endif
        }
#if !os(tvOS)
        .navigationTitle("Home")
#endif
        .toolbar {
#if os(macOS)
            ToolbarItem(placement: .navigation) {
                Button {
                    reloadHome = true
                    viewModel.reload()
                } label: {
                    Label("Reload", systemImage: "arrow.clockwise")
                        .labelStyle(.iconOnly)
                }
                .keyboardShortcut("r", modifiers: .command)
            }
            ToolbarItem {
                NavigationLink(value: Screens.notifications) {
                    Label("Notifications", systemImage: hasNotifications ? "bell.badge.fill" : "bell")
                        .labelStyle(.iconOnly)
                }
            }
#elseif os(iOS) || os(visionOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    NavigationLink(value: Screens.notifications) {
                        Image(systemName: hasNotifications ? "bell.badge.fill" : "bell")
                            .accessibilityLabel("Notifications")
                    }
                    NavigationLink(value: SettingsScreens.settings) {
                        Image(systemName: "gearshape")
                            .accessibilityLabel("Settings")
                    }
                }
            }
#endif
        }
#if !os(macOS)
        .sheet(isPresented: $displayOnboard) {
            WelcomeView()
        }
#endif
        .task {
            let notifications = await NotificationManager.shared.hasDeliveredItems()
            hasNotifications = notifications
        }
        .task(id: homeSections.visibleOrderedSections.map(\.rawValue).joined(separator: ",")) {
            await viewModel.load(visibleKinds: homeSections.visibleOrderedSections)
        }
        .onChange(of: homeSections.order) { _, _ in
            viewModel.reload()
        }
        .onChange(of: homeSections.hidden) { _, _ in
            viewModel.reload()
        }
    }

    @ViewBuilder
    private func homeSectionView(_ section: HomeSectionKind) -> some View {
        switch section {
        case .upNext:
            HorizontalUpNextListView(shouldReload: $reloadHome)
        case .upcomingWatchlist:
            UpcomingWatchlist(shouldReload: $reloadHome)
        case .pins:
            PinItemsList(showPopup: $showPopup, popupType: $popupType, shouldReload: $reloadHome)
        case .favoriteLists:
            HorizontalPinnedList(showPopup: $showPopup, popupType: $popupType, shouldReload: $reloadHome)
        case .trending:
            HorizontalItemContentListView(items: viewModel.trending,
                                          title: section.title,
                                          subtitle: section.subtitle,
                                          showPopup: $showPopup,
                                          popupType: $popupType)
        case .moviesUpcoming, .moviesNowPlaying, .moviesPopular, .moviesTopRated, .tvPopular, .tvTopRated:
            if let endpoint = section.endpoint {
                let items = viewModel.sectionResults[endpoint] ?? []
                if !items.isEmpty {
                    HorizontalItemContentListView(items: items,
                                                  title: section.title,
                                                  subtitle: section.subtitle,
                                                  showPopup: $showPopup,
                                                  popupType: $popupType,
                                                  endpoint: endpoint)
                }
            }
        }
    }
    
    private func checkVersion() {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let lastSeenVersion = UserDefaults.standard.string(forKey: UserDefaults.lastSeenAppVersionKey)
        if SettingsStore.shared.displayOnboard {
            return
        } else {
            if currentVersion != lastSeenVersion {
                // showWhatsNew.toggle()
                UserDefaults.standard.set(currentVersion, forKey: UserDefaults.lastSeenAppVersionKey)
            }
        }
    }
    
#if os(iOS)
    private func checkAskForReview() {
        if launchCount < 30 {
            launchCount += 1
        } else {
            if !askedForReview {
                withAnimation { showReviewBanner = true }
            }
            askedForReview = true
        }
    }
#endif
}

#Preview {
    HomeView()
}


