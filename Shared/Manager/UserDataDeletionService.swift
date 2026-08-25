//
//  UserDataDeletionService.swift
//  Cronica
//

import CoreData
import Foundation
import Nuke
#if canImport(WidgetKit) && !os(watchOS)
import WidgetKit
#endif

enum UserDataDeletionError: LocalizedError {
    case deletionFailed(String)

    var errorDescription: String? {
        switch self {
        case .deletionFailed(let message):
            return message
        }
    }
}

@MainActor
enum UserDataDeletionService {
    static func deleteAllUserData() async throws {
        NotificationManager.shared.removeAllNotifications()
        CalendarManager.shared.removeAllCalendarData()

        let persistence = PersistenceController.shared
        do {
            try persistence.deleteAllUserContent()
        } catch {
            throw UserDataDeletionError.deletionFailed(error.localizedDescription)
        }

        resetUserDefaults()
        clearCaches()
        reloadWidgets()
        applyFreshAppDefaults()
    }

    private static func resetUserDefaults() {
        let keys = [
            "showOnboarding",
            "displayDeveloperSettings",
            "gesture",
            "appThemeColor",
            "watchlistStyle",
            "disableTranslucentBackground",
            "user_theme",
            "openInYouTube",
            "markEpisodeWatchedTap",
            "enableHapticFeedback",
            "enableWatchProviders",
            "selectedWatchProviderRegion",
            "primaryLeftSwipe",
            "secondaryLeftSwipe",
            "primaryRightSwipe",
            "secondaryRightSwipe",
            "allowFullSwipe",
            "allowNotifications",
            "notifyMovies",
            "notifyTVShows",
            "allowCalendarSync",
            "syncCalendarMovies",
            "syncCalendarTVShows",
            "userHasPurchasedTipJar",
            "itemContentListDisplayType",
            "exploreDisplayType",
            "preferCompactUI",
            "selectedWatchProviderEnabled",
            "selectedWatchProviders",
            "userHasImportedFromTMDB",
            "isUserConnectedWithTMDB",
            "showRemoveConfirmation",
            "choosePreferredLaunchScreen",
            "preferredLaunchScreen",
            "removeFromPinOnWatched",
            "autoOpenCustomListSelector",
            "alwaysUsePosterAsCover",
            "shareLinkPreference",
            "upNextStyle",
            "upNextSortOrder",
            "hideUnstartedUpNext",
            "showDateOnWatchlistRow",
            "disableSearchFilter",
            "removeFromWatchingOnRenew",
            "hideEpisodeTitles",
            "hideEpisodeThumbnails",
            "preferCoverOnUpNext",
            "markUpNextWatchedOnTap",
            "confirmationForMarkOnTapUpNext",
            "showMenuBarApp",
            "notificationHour",
            "notificationMinute",
            "askConfirmationWhenMarkingEpisodeWatched",
            "cronicaCalendarEventIDs",
            "lastMaintenance",
            "lastWatchingRefreshKey",
            "lastUpcomingRefreshKey",
            UserDefaults.lastSeenAppVersionKey,
            "launchCount",
            "askedForReview",
            "lastTabSelected",
            "selectedOrder",
            "watchlistShowAllItems",
            "watchlistMediaTypeFilter",
            "defaultWatchlistSortOrder",
            "exploreViewSelectedGenre",
            "exploreViewSelectedMedia",
            "exploreViewHideAddedItems",
            "selectedTabExplore",
            "firstLocaleCheck",
            "alwaysShowConfirmationWatchProvider",
            "customListShowAllItems",
            "customListMediaTypeFilter",
            "customListSmartFilter",
            "customListSortOrder",
            "selectedView"
        ]

        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    private static func clearCaches() {
        DataLoader.sharedUrlCache.removeAllCachedResponses()
        ImageCache.shared.removeAll()
    }

    private static func reloadWidgets() {
#if canImport(WidgetKit) && !os(watchOS)
        WidgetCenter.shared.reloadAllTimelines()
#endif
    }

    private static func applyFreshAppDefaults() {
        let settings = SettingsStore.shared
        settings.displayOnboard = true
        settings.allowCalendarSync = false
        settings.allowNotifications = false
    }
}
