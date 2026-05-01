import XCTest
@testable import Cronica

final class AdConfigurationTests: XCTestCase {

    // MARK: - Ad Unit ID Format

    func testNativeAdUnitIDHasCorrectPrefix() {
        XCTAssertTrue(
            AdConfiguration.AdUnitID.native.hasPrefix("ca-app-pub-"),
            "Native ad unit ID must start with 'ca-app-pub-'"
        )
    }

    func testInterstitialAdUnitIDHasCorrectPrefix() {
        XCTAssertTrue(
            AdConfiguration.AdUnitID.interstitial.hasPrefix("ca-app-pub-"),
            "Interstitial ad unit ID must start with 'ca-app-pub-'"
        )
    }

    func testRewardedAdUnitIDHasCorrectPrefix() {
        XCTAssertTrue(
            AdConfiguration.AdUnitID.rewarded.hasPrefix("ca-app-pub-"),
            "Rewarded ad unit ID must start with 'ca-app-pub-'"
        )
    }

    func testAppOpenAdUnitIDHasCorrectPrefix() {
        XCTAssertTrue(
            AdConfiguration.AdUnitID.appOpen.hasPrefix("ca-app-pub-"),
            "App open ad unit ID must start with 'ca-app-pub-'"
        )
    }

    func testAdUnitIDsAreNotEmpty() {
        XCTAssertFalse(AdConfiguration.AdUnitID.native.isEmpty)
        XCTAssertFalse(AdConfiguration.AdUnitID.interstitial.isEmpty)
        XCTAssertFalse(AdConfiguration.AdUnitID.rewarded.isEmpty)
        XCTAssertFalse(AdConfiguration.AdUnitID.appOpen.isEmpty)
    }

    func testAdUnitIDsAreDifferent() {
        let ids = [
            AdConfiguration.AdUnitID.native,
            AdConfiguration.AdUnitID.interstitial,
            AdConfiguration.AdUnitID.rewarded,
            AdConfiguration.AdUnitID.appOpen,
        ]

        XCTAssertEqual(
            Set(ids).count,
            ids.count,
            "All ad placements must use distinct ad unit IDs"
        )
    }

    func testAdUnitIDsAreNotGoogleTestIDs() {
        // Google's well-known test ad unit IDs
        let testIDs = [
            "ca-app-pub-3940256099942544/2934735716", // test banner
            "ca-app-pub-3940256099942544/4411468910", // test interstitial
            "ca-app-pub-3940256099942544/1712485313", // test rewarded
            "ca-app-pub-3940256099942544/3986624511", // test native
            "ca-app-pub-3940256099942544/6300978111", // test app open
        ]
        XCTAssertFalse(testIDs.contains(AdConfiguration.AdUnitID.native),
                        "Production build must not use Google test ad unit IDs")
        XCTAssertFalse(testIDs.contains(AdConfiguration.AdUnitID.interstitial),
                        "Production build must not use Google test ad unit IDs")
        XCTAssertFalse(testIDs.contains(AdConfiguration.AdUnitID.rewarded),
                        "Production build must not use Google test ad unit IDs")
        XCTAssertFalse(testIDs.contains(AdConfiguration.AdUnitID.appOpen),
                        "Production build must not use Google test ad unit IDs")
    }

    // MARK: - Policy Compliance

    func testNativeRefreshIntervalMeetsGoogleMinimum() {
        // Google AdMob policy: minimum 30 seconds between native ad refreshes
        XCTAssertGreaterThanOrEqual(
            AdConfiguration.nativeRefreshInterval, 30,
            "Native ad refresh interval must be >= 30s per Google policy"
        )
    }

    func testInterstitialCooldownAllowsImmediateRepeatPresentation() {
        XCTAssertEqual(
            AdConfiguration.interstitialCooldown, 0,
            "Interstitial cooldown should be disabled so repeat eligible actions can monetize immediately"
        )
    }

    func testAppOpenCooldownAllowsImmediateForegroundPresentation() {
        XCTAssertEqual(
            AdConfiguration.appOpenCooldown, 0,
            "App open cooldown should be disabled so foreground returns can monetize immediately"
        )
    }

    func testNativeInitialRequestDelayDoesNotThrottleStartupRequests() {
        XCTAssertEqual(
            AdConfiguration.nativeInitialRequestDelay, 0,
            "Native request startup delay should be disabled so monetized screens request immediately"
        )
    }
}
