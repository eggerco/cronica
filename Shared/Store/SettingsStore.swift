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
    @AppStorage("watchlistStyle") var watchlistStyle: SectionDetailsPreferredStyle = UIDevice.isIPhone ? .list : .poster
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
#else
    @AppStorage("allowNotifications") var allowNotifications = true
    @AppStorage("notifyMovies") var notifyMovieRelease = true
    @AppStorage("notifyTVShows") var notifyNewEpisodes = true
#endif
    @AppStorage("userHasPurchasedTipJar") var hasPurchasedTipJar = false
#if os(tvOS)
    @AppStorage("itemContentListDisplayType") var listsDisplayType: ItemContentListPreferredDisplayType = .card
#else
    @AppStorage("itemContentListDisplayType") var listsDisplayType: ItemContentListPreferredDisplayType = .standard
#endif
#if os(iOS)
    @AppStorage("exploreDisplayType") var sectionStyleType: SectionDetailsPreferredStyle = UIDevice.isIPhone ? .card : .poster
#else
    @AppStorage("exploreDisplayType") var sectionStyleType: SectionDetailsPreferredStyle = .card
#endif
    @AppStorage("preferCompactUI") var isCompactUI = false
    @AppStorage("selectedWatchProviderEnabled") var isSelectedWatchProviderEnabled = false
    @AppStorage("selectedWatchProviders") var selectedWatchProviders = ""
    @AppStorage("userHasImportedFromTMDB") var userImportedTMDB = false
    @AppStorage("isUserConnectedWithTMDB") var isUserConnectedWithTMDb = false
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

