//
//  HomeView.swift
//  Story
//
//  Created by Alexandre Madeira on 10/02/22.
//

import SwiftUI
#if os(iOS)
import AdmobSwiftUI
#endif

struct HomeView: View {
    static let tag: Screens? = .home
#if os(tvOS) || os(macOS)
    @AppStorage("showOnboarding") private var displayOnboard = false
#else
    @AppStorage("showOnboarding") private var displayOnboard = true
#endif
    @StateObject private var viewModel = HomeViewModel()
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
    @StateObject private var nativeViewModel = NativeAdViewModel(
        adUnitID: AdConfiguration.AdUnitID.native,
        requestInterval: AdConfiguration.nativeRefreshInterval
    )
#endif
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
#if os(iOS)
                if showReviewBanner { CallToReviewAppView(showView: $showReviewBanner).unredacted() }
                if HomeAdPolicy.shouldShowNativeAd(
                    hasPurchasedTipJar: SettingsStore.shared.hasPurchasedTipJar,
                    monetizationDisabled: PreviewVideoRuntime.shouldDisableMonetization()
                ) {
                    NativeAdView(nativeViewModel: nativeViewModel, style: .card)
                        .frame(height: 320)
                        .padding(.horizontal)
                        .onAppear {
                            nativeViewModel.refreshAd()
                        }
                }
#endif
                HorizontalUpNextListView(shouldReload: $reloadHome)
                UpcomingWatchlist(shouldReload: $reloadHome)
                PinItemsList(showPopup: $showPopup, popupType: $popupType, shouldReload: $reloadHome)
                HorizontalPinnedList(showPopup: $showPopup, popupType: $popupType, shouldReload: $reloadHome)
                HorizontalItemContentListView(items: viewModel.trending,
                                              title: NSLocalizedString("Trending", comment: ""),
                                              subtitle: NSLocalizedString("Today", comment: ""),
                                              showPopup: $showPopup,
                                              popupType: $popupType)
                ForEach(viewModel.sections) { section in
                    HorizontalItemContentListView(items: section.results,
                                                  title: section.title,
                                                  subtitle: section.subtitle,
                                                  showPopup: $showPopup,
                                                  popupType: $popupType,
                                                  endpoint: section.endpoint)
                }
                AttributionView()
            }
        }
#if os(iOS)
        .refreshable {
            reloadHome = true
            viewModel.reload()
        }
        .onAppear {
            checkAskForReview()
        }
#endif
        .overlay { if !viewModel.isLoaded { CronicaLoadingPopupView() } }
        .actionPopup(isShowing: $showPopup, for: popupType)
#if os(tvOS)
        .ignoresSafeArea(.all, edges: .horizontal)
#endif
        .onAppear {
            checkVersion()
#if os(iOS) || os(macOS)
            Task {
                let notifications = await NotificationManager.shared.hasDeliveredItems()
                hasNotifications = notifications
            }
#endif
        }
        .navigationDestination(for: ItemContent.self) { item in
            ItemContentDetails(title: item.itemTitle,
                               id: item.id,
                               type: item.itemContentMedia)
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
        .navigationDestination(for: WatchlistItem.self) { item in
            ItemContentDetails(title: item.itemTitle,
                               id: item.itemId,
                               type: item.itemMedia)
#if os(tvOS)
            .ignoresSafeArea(.all, edges: .horizontal)
#endif
        }
        .navigationDestination(for: Endpoints.self) { endpoint in
            EndpointDetails(title: endpoint.title,
                            endpoint: endpoint)
        }
#if !os(tvOS)
        .navigationDestination(for: [WatchlistItem].self) { item in
            WatchlistSectionDetails(items: item)
        }
        .navigationDestination(for: [String:[WatchlistItem]].self) { item in
            let title = item.map { (key, _) in key }.first
            let items = item.map { (_, value) in value }.first
            if let title, let items {
                WatchlistSectionDetails(title: title, items: items)
            }
        }
#endif
        .navigationDestination(for: [String:[ItemContent]].self) { item in
            let keys = item.map { (key, _) in key }
            let value = item.map { (_, value) in value }
            ItemContentSectionDetails(title: keys[0], items: value[0])
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
        .navigationDestination(for: SettingsScreens.self) { settings in
            switch settings {
            case .about: AboutSettings()
            case .appearance: AppearanceSetting()
            case .behavior: BehaviorSetting()
            case .developer:
#if os(tvOS)
                EmptyView()
#else
                DeveloperView()
#endif
            case .notifications: NotificationsSettingsView()
            case .tipJar: TipJarSetting()
            case .feedback: FeedbackComposerView()
            case .region: WatchProviderSettings()
            case .settings: SettingsView()
            case .watchlist: WatchlistSettingsView()
            case .season: SeasonUpNextSettingsView()
            }
        }
        .redacted(reason: !viewModel.isLoaded ? .placeholder : [] )
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
                            .fontDesign(.rounded)
                            .fontWeight(.semibold)
                            .imageScale(.medium)
                            .accessibilityLabel("Notifications")
                            .applyHoverEffect()
                    }
                    NavigationLink(value: SettingsScreens.settings) {
                        Image(systemName: "gearshape")
                            .fontDesign(.rounded)
                            .fontWeight(.semibold)
                            .imageScale(.medium)
                            .accessibilityLabel("Settings")
                            .applyHoverEffect()
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
#if !os(tvOS)
        .navigationDestination(for: Screens.self) { screen in
            if screen == .notifications {
                NotificationListView(showNotification: $showNotifications)
            }
        }
#endif
        .task {
            let notifications = await NotificationManager.shared.hasDeliveredItems()
            hasNotifications = notifications
        }
        .task {
            await viewModel.load()
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

