import Foundation

/// Centralized configuration for all AdMob ad units and settings.
enum AdConfiguration {
    /// AdMob ad unit IDs
    enum AdUnitID {
        static let native = "ca-app-pub-7891478850122465/8171033829"
        static let interstitial = "ca-app-pub-7891478850122465/6565020438"
        static let rewarded = "ca-app-pub-7891478850122465/1859860932"
        static let appOpen = "ca-app-pub-7891478850122465/6721664164"
    }

    /// Native ad refresh interval in seconds (Google policy minimum: 30s)
    static let nativeRefreshInterval: Int = 30

    /// Delay before first native ad request on a screen (seconds).
    static let nativeInitialRequestDelay: TimeInterval = 0

    /// Minimum seconds between interstitial presentations
    static let interstitialCooldown: TimeInterval = 0

    /// Minimum seconds between app open ad presentations
    static let appOpenCooldown: TimeInterval = 0
}

enum PuzzleAdPolicy {
    static func shouldShowNativeAd(
        hasPurchasedTipJar: Bool,
        monetizationDisabled: Bool
    ) -> Bool {
        !hasPurchasedTipJar && !monetizationDisabled
    }
}

enum HomeAdPolicy {
    static func shouldShowNativeAd(
        hasPurchasedTipJar: Bool,
        monetizationDisabled: Bool
    ) -> Bool {
        !hasPurchasedTipJar && !monetizationDisabled
    }
}

enum DetailAdPolicy {
    static func shouldShowNativeAd(
        hasPurchasedTipJar: Bool,
        monetizationDisabled: Bool
    ) -> Bool {
        !hasPurchasedTipJar && !monetizationDisabled
    }
}

enum SearchAdPolicy {
    static func shouldShowNativeAd(
        hasPurchasedTipJar: Bool,
        monetizationDisabled: Bool,
        resultCount: Int
    ) -> Bool {
        resultCount > 0 && !hasPurchasedTipJar && !monetizationDisabled
    }
}
