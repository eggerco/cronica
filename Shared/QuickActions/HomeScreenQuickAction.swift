//
//  HomeScreenQuickAction.swift
//  Cronica
//

#if os(iOS)
import Foundation

enum HomeScreenQuickAction: String {
    case search = "dev.alexandremadeira.cronica.quickAction.search"
    case watchlist = "dev.alexandremadeira.cronica.quickAction.watchlist"
    case upNext = "dev.alexandremadeira.cronica.quickAction.upNext"
    case markUpNextEpisode = "dev.alexandremadeira.cronica.quickAction.markUpNextEpisode"

    init?(shortcutType: String) {
        self.init(rawValue: shortcutType)
    }

    var pendingNavigation: PendingAppNavigation {
        switch self {
        case .search: .search
        case .watchlist: .watchlist
        case .upNext: .upNext
        case .markUpNextEpisode: .markUpNextEpisode
        }
    }
}
#endif
