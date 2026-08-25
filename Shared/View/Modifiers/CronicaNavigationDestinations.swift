//
//  CronicaNavigationDestinations.swift
//  Cronica
//

import SwiftUI

#if !os(watchOS)
extension View {
    /// Shared detail routes used across tabs and lists.
    func cronicaStandardNavigationDestinations(itemContentHandleToolbar: Bool = false) -> some View {
        navigationDestination(for: ItemContent.self) { item in
            ItemContentDetails(
                title: item.itemTitle,
                id: item.id,
                type: item.itemContentMedia,
                handleToolbar: itemContentHandleToolbar
            )
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
        .navigationDestination(for: [String: [ItemContent]].self) { item in
            let title = item.map { (key, _) in key }.first
            let items = item.map { (_, value) in value }.first
            if let title, let items {
#if os(tvOS)
                EmptyView()
#else
                ItemContentSectionDetails(title: title, items: items)
#endif
            }
        }
        .navigationDestination(for: [Person].self) { items in
#if os(tvOS)
            EmptyView()
#else
            DetailedPeopleList(items: items)
#endif
        }
        .navigationDestination(for: ProductionCompany.self) { item in
            CompanyDetails(company: item)
        }
        .navigationDestination(for: [ProductionCompany].self) { item in
            CompaniesListView(companies: item)
        }
    }

    func cronicaWatchlistNavigationDestinations(itemContentHandleToolbar: Bool = false) -> some View {
        cronicaStandardNavigationDestinations(itemContentHandleToolbar: itemContentHandleToolbar)
            .navigationDestination(for: WatchlistItem.self) { item in
                ItemContentDetails(title: item.itemTitle, id: item.itemId, type: item.itemMedia)
#if os(tvOS)
                .ignoresSafeArea(.all, edges: .horizontal)
#endif
            }
            .navigationDestination(for: ReleaseCalendarRoute.self) { _ in
                ReleaseCalendarView()
            }
    }

    func cronicaHomeNavigationDestinations(showNotifications: Binding<Bool>) -> some View {
        cronicaWatchlistNavigationDestinations()
            .navigationDestination(for: Endpoints.self) { endpoint in
                EndpointDetails(title: endpoint.title, endpoint: endpoint)
            }
#if !os(tvOS)
            .navigationDestination(for: [WatchlistItem].self) { item in
                WatchlistSectionDetails(items: item)
            }
            .navigationDestination(for: [String: [WatchlistItem]].self) { item in
                let title = item.map { (key, _) in key }.first
                let items = item.map { (_, value) in value }.first
                if let title, let items {
                    WatchlistSectionDetails(title: title, items: items)
                }
            }
            .navigationDestination(for: Screens.self) { screen in
                if screen == .notifications {
                    NotificationListView(showNotification: showNotifications)
                }
            }
#endif
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
                case .feedback: FeedbackComposerView()
                case .region: WatchProviderSettings()
                case .settings: SettingsView()
                case .watchlist: WatchlistSettingsView()
                case .season: SeasonUpNextSettingsView()
                case .dataManagement: DataManagementSettingsView()
                case .integrations: IntegrationsSettingsView()
                case .simkl: SimklSettingsView()
                case .tmdbAccount: TMDBAccountSettingsView()
                }
            }
    }

    func cronicaSearchNavigationDestinations() -> some View {
        cronicaStandardNavigationDestinations()
            .navigationDestination(for: SearchItemContent.self) { item in
                if item.media == .person {
                    PersonDetailsView(name: item.itemTitle, id: item.id)
#if os(tvOS)
                    .ignoresSafeArea(.all, edges: .horizontal)
#endif
                } else {
                    ItemContentDetails(title: item.itemTitle, id: item.id, type: item.media)
#if os(tvOS)
                    .ignoresSafeArea(.all, edges: .horizontal)
#endif
                }
            }
            .navigationDestination(for: CombinedKeywords.self) { keyword in
                KeywordSectionView(keyword: keyword)
#if os(tvOS)
                .ignoresSafeArea(.all, edges: .horizontal)
#endif
            }
    }
}
#endif
