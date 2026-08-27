//
//  UserDataDeletionService.swift
//  Cronica
//

import CoreData
import CronicaCore
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
#if canImport(EventKit) && !os(tvOS) && !os(watchOS)
        RemindersManager.shared.removeAllReminders()
#endif
#if canImport(CoreSpotlight) && !os(watchOS) && !os(tvOS)
        SpotlightRefreshBridge.clearIfAvailable()
#endif

        let persistence = PersistenceController.shared
        do {
            try persistence.deleteAllUserContent()
        } catch {
            throw UserDataDeletionError.deletionFailed(error.localizedDescription)
        }

        SimklTokenStore.delete()
        SimklKnownItemsStore.clear()
#if !os(watchOS)
        SimklPushService.shared.clearQueue()
        TMDBSessionStore.delete()
        TMDBPushService.shared.clearQueue()
        TMDBAccountListCache.clear()
#endif

        resetUserDefaults()
        clearCaches()
        WidgetSnapshotStore.removeAllSnapshots()
        LiveActivityPosterStore.removeAll()
#if os(iOS)
        await WatchingSessionManager.shared.endSession()
#endif
        reloadWidgets()
        applyFreshAppDefaults()
    }

    /// Visible to tests — clears prefs without touching Core Data / Keychain.
    static func resetUserDefaultsForTesting() {
        resetUserDefaults()
        applyFreshAppDefaults()
    }

    private static func resetUserDefaults() {
        let keys = [
            "showOnboarding",
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
            "itemContentListDisplayType",
            "exploreDisplayType",
            "preferCompactUI",
            "selectedWatchProviderEnabled",
            "selectedWatchProviders",
            "userHasImportedFromTMDB",
            "isUserConnectedWithTMDB",
            "tmdbAccountName",
            "tmdbAccountLastImportTimestamp",
            "isSimklConnected",
            "tmdbAccountID",
            "tmdbPushEnabled",
            "tmdbLastSyncCheck",
            "tmdbPushQueue",
            "tmdbAccountListFingerprint",
            "simklLastImportTimestamp",
            "simklActivitiesAll",
            "simklRemovedMovies",
            "simklRemovedShows",
            "simklRemovedAnime",
            "simklTVWatching",
            "simklTVHold",
            "simklAnimeWatching",
            "simklAnimeHold",
            "simklLastActivitiesCheck",
            "simklPushEnabled",
            "simklAccountID",
            "simklAccountName",
            "simklLastStatsFetch",
            "simklKnownContentIDs",
            "simklPushQueue",
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
            "selectedView",
            "homeSectionOrder",
            "homeSectionHidden",
            "homePinnedListSortOrder",
            "persistentHistory.lastToken"
        ]

        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    private static func clearCaches() {
        DataLoader.sharedUrlCache.removeAllCachedResponses()
        ImageCache.shared.removeAll()
        if let dataCache = ImagePipeline.shared.configuration.dataCache as? DataCache {
            dataCache.removeAll()
        }
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
        settings.isSimklConnected = false
        settings.simklLastImportDate = nil
        settings.simklActivitiesAll = ""
        settings.simklRemovedMovies = ""
        settings.simklRemovedShows = ""
        settings.simklRemovedAnime = ""
        settings.simklTVWatching = ""
        settings.simklTVHold = ""
        settings.simklAnimeWatching = ""
        settings.simklAnimeHold = ""
        settings.markSimklActivitiesChecked(Date(timeIntervalSince1970: 0))
        settings.simklPushEnabled = false
        settings.simklAccountID = 0
        settings.simklAccountName = ""
        settings.simklLastStatsFetchDate = nil
        settings.isUserConnectedWithTMDb = false
        settings.tmdbAccountName = ""
        settings.tmdbAccountLastImportDate = nil
        settings.tmdbPushEnabled = false
        settings.markTMDBSyncChecked(Date(timeIntervalSince1970: 0))
#if os(macOS)
        // Mac has no Welcome sheet — avoid leaving a dead onboarding flag.
        settings.displayOnboard = false
#endif
#if !os(watchOS)
        HomeSectionStore.shared.resetToDefaults()
#endif
    }
}
