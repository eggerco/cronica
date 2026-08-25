//
//  SettingsStore.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 11/05/22.
//

import SwiftUI

final class SettingsStore: ObservableObject {
    private init() { }
    static var shared = SettingsStore()
    @AppStorage("showOnboarding") var displayOnboard = true
    @AppStorage("displayDeveloperSettings") var displayDeveloperSettings = false
    @AppStorage("gesture") var gesture: UpdateItemProperties = .favorite
    @AppStorage("appThemeColor") var appTheme: AppThemeColors = .blue
#if os(iOS)
    @AppStorage("watchlistStyle") var watchlistStyle: SectionDetailsPreferredStyle = .list
#else
    @AppStorage("watchlistStyle") var watchlistStyle: SectionDetailsPreferredStyle = .card
#endif
    @AppStorage("disableTranslucentBackground") var disableTranslucent = false
    @AppStorage("user_theme") var currentTheme: AppTheme = .system
    @AppStorage("openInYouTube") var openInYouTube = false
    @AppStorage("markEpisodeWatchedTap") var markEpisodeWatchedOnTap = false
    @AppStorage("enableHapticFeedback") var hapticFeedback = true
    @AppStorage("enableWatchProviders") var isWatchProviderEnabled = true
    @AppStorage("selectedWatchProviderRegion") var watchRegion: AppContentRegion = .us
    @AppStorage("primaryLeftSwipe") var primaryLeftSwipe: SwipeGestureOptions = .markWatch
    @AppStorage("secondaryLeftSwipe") var secondaryLeftSwipe: SwipeGestureOptions = .markFavorite
    @AppStorage("primaryRightSwipe") var primaryRightSwipe: SwipeGestureOptions = .delete
    @AppStorage("secondaryRightSwipe") var secondaryRightSwipe: SwipeGestureOptions = .markArchive
    @AppStorage("allowFullSwipe") var allowFullSwipe = false
#if os(macOS)
    @AppStorage("allowNotifications") var allowNotifications = false
    @AppStorage("notifyMovies") var notifyMovieRelease = false
    @AppStorage("notifyTVShows") var notifyNewEpisodes = false
    @AppStorage("allowCalendarSync") var allowCalendarSync = false
    @AppStorage("syncCalendarMovies") var syncCalendarMovies = true
    @AppStorage("syncCalendarTVShows") var syncCalendarTVShows = true
#else
    @AppStorage("allowNotifications") var allowNotifications = true
    @AppStorage("notifyMovies") var notifyMovieRelease = true
    @AppStorage("notifyTVShows") var notifyNewEpisodes = true
    @AppStorage("allowCalendarSync") var allowCalendarSync = false
    @AppStorage("syncCalendarMovies") var syncCalendarMovies = true
    @AppStorage("syncCalendarTVShows") var syncCalendarTVShows = true
#endif
    @AppStorage("userHasPurchasedTipJar") var hasPurchasedTipJar = false
#if os(tvOS)
    @AppStorage("itemContentListDisplayType") var listsDisplayType: ItemContentListPreferredDisplayType = .card
#else
    @AppStorage("itemContentListDisplayType") var listsDisplayType: ItemContentListPreferredDisplayType = .standard
#endif
#if os(iOS)
    @AppStorage("exploreDisplayType") var sectionStyleType: SectionDetailsPreferredStyle = .card
#else
    @AppStorage("exploreDisplayType") var sectionStyleType: SectionDetailsPreferredStyle = .card
#endif
    @AppStorage("preferCompactUI") var isCompactUI = false
    @AppStorage("selectedWatchProviderEnabled") var isSelectedWatchProviderEnabled = false
    @AppStorage("selectedWatchProviders") var selectedWatchProviders = ""
    @AppStorage("userHasImportedFromTMDB") var userImportedTMDB = false
    @AppStorage("isUserConnectedWithTMDB") var isUserConnectedWithTMDb = false
    @AppStorage("tmdbAccountName") var tmdbAccountName = ""
    @AppStorage("tmdbAccountLastImportTimestamp") private var tmdbAccountLastImportTimestamp: Double = 0
    var tmdbAccountLastImportDate: Date? {
        get { tmdbAccountLastImportTimestamp > 0 ? Date(timeIntervalSince1970: tmdbAccountLastImportTimestamp) : nil }
        set { tmdbAccountLastImportTimestamp = newValue?.timeIntervalSince1970 ?? 0 }
    }
    @AppStorage("isSimklConnected") var isSimklConnected = false
    @AppStorage("simklLastImportTimestamp") private var simklLastImportTimestamp: Double = 0
    var simklLastImportDate: Date? {
        get { simklLastImportTimestamp > 0 ? Date(timeIntervalSince1970: simklLastImportTimestamp) : nil }
        set { simklLastImportTimestamp = newValue?.timeIntervalSince1970 ?? 0 }
    }
    @AppStorage("simklActivitiesAll") var simklActivitiesAll = ""
    @AppStorage("simklRemovedMovies") var simklRemovedMovies = ""
    @AppStorage("simklRemovedShows") var simklRemovedShows = ""
    @AppStorage("simklRemovedAnime") var simklRemovedAnime = ""
    @AppStorage("simklTVWatching") var simklTVWatching = ""
    @AppStorage("simklTVHold") var simklTVHold = ""
    @AppStorage("simklAnimeWatching") var simklAnimeWatching = ""
    @AppStorage("simklAnimeHold") var simklAnimeHold = ""
    @AppStorage("simklLastActivitiesCheck") private var simklLastActivitiesCheck = 0.0
    var simklLastActivitiesCheckTimestamp: TimeInterval { simklLastActivitiesCheck }
    func markSimklActivitiesChecked(_ date: Date = Date()) {
        simklLastActivitiesCheck = date.timeIntervalSince1970
    }
    @AppStorage("simklPushEnabled") var simklPushEnabled = false
    @AppStorage("simklAccountID") var simklAccountID = 0
    @AppStorage("simklAccountName") var simklAccountName = ""
    @AppStorage("simklLastStatsFetch") private var simklLastStatsFetch = 0.0
    var simklLastStatsFetchDate: Date? {
        get { simklLastStatsFetch > 0 ? Date(timeIntervalSince1970: simklLastStatsFetch) : nil }
        set { simklLastStatsFetch = newValue?.timeIntervalSince1970 ?? 0 }
    }
    @AppStorage("showRemoveConfirmation") var showRemoveConfirmation = true
    @AppStorage("choosePreferredLaunchScreen") var isPreferredLaunchScreenEnabled = false
#if !os(watchOS)
    @AppStorage("preferredLaunchScreen") var preferredLaunchScreen: Screens = .home
#else
    @AppStorage("preferredLaunchScreen") var preferredLaunchScreen: Screens = .watchlist
#endif
    @AppStorage("removeFromPinOnWatched") var removeFromPinOnWatched = false
    @AppStorage("autoOpenCustomListSelector") var openListSelectorOnAdding = false
    @AppStorage("alwaysUsePosterAsCover") var usePostersAsCover = true
    @AppStorage("shareLinkPreference") var shareLinkPreference: ShareLinkPreference = .tmdb
    @AppStorage("upNextStyle") var upNextStyle: UpNextDetailsPreferredStyle = .card
    @AppStorage("upNextSortOrder") var upNextSortOrder: UpNextSortOrder = .recentActivity
    @AppStorage("hideUnstartedUpNext") var hideUnstartedUpNext = false
    @AppStorage("showDateOnWatchlistRow") var showDateOnWatchlist = true
    @AppStorage("disableSearchFilter") var disableSearchFilter = false
    @AppStorage("removeFromWatchingOnRenew") var removeFromWatchOnRenew = false
    @AppStorage("hideEpisodeTitles") var hideEpisodesTitles = false
    @AppStorage("hideEpisodeThumbnails") var hideEpisodesThumbnails = false
    @AppStorage("preferCoverOnUpNext") var preferCoverOnUpNext = false
    @AppStorage("markUpNextWatchedOnTap") var markWatchedOnTapUpNext = false
    @AppStorage("confirmationForMarkOnTapUpNext") var askForConfirmationUpNext = true
#if os(macOS)
    @AppStorage("showMenuBarApp") var showMenuBarApp = true
#endif
    @AppStorage("notificationHour") var notificationHour = 7
    @AppStorage("notificationMinute") var notificationMinute = 0
    @AppStorage("askConfirmationWhenMarkingEpisodeWatched") var askConfirmationToMarkEpisodeWatched = true
}

