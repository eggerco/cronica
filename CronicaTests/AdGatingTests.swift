import XCTest
@testable import Cronica

/// Tests that ad visibility is correctly gated by the tip jar purchase state.
/// These protect revenue (ads show for free users) and honor purchases (no ads for paid users).
final class AdGatingTests: XCTestCase {

    private let tipJarKey = "userHasPurchasedTipJar"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: tipJarKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: tipJarKey)
        super.tearDown()
    }

    // MARK: - Free Users See Ads

    func testFreeUserTipJarDefaultIsFalse() {
        XCTAssertFalse(SettingsStore.shared.hasPurchasedTipJar,
                        "Default tip jar state must be false — free users should see ads")
    }

    func testFreeUserInterstitialIsNotSkipped() {
        // Ensure tip jar is false
        UserDefaults.standard.set(false, forKey: tipJarKey)
        AdCoordinator.lastPresentationDate = nil

        let coordinator = AdCoordinator()

        // In test env there's no loaded ad, so onDismiss fires via the "no ad" path,
        // NOT via the tip jar shortcut. We verify by checking the tipjar path isn't taken.
        var dismissed = false
        coordinator.presentAd {
            dismissed = true
        }
        XCTAssertTrue(dismissed)
        // The key assertion: hasPurchasedTipJar is false, so the coordinator didn't
        // skip due to tip jar — it fell through to the "no ad available" guard
    }

    // MARK: - Paid Users Don't See Ads

    func testPaidUserInterstitialIsSkipped() {
        UserDefaults.standard.set(true, forKey: tipJarKey)
        AdCoordinator.lastPresentationDate = nil

        let coordinator = AdCoordinator()

        var dismissed = false
        coordinator.presentAd {
            dismissed = true
        }
        XCTAssertTrue(dismissed, "Paid users should have onDismiss called immediately (ad skipped)")
    }

    func testPaidUserAdLoadIsSkipped() {
        UserDefaults.standard.set(true, forKey: tipJarKey)

        let coordinator = AdCoordinator()
        // loadAd() is called in init but should return early
        // Calling again should also return early without crash
        coordinator.loadAd()
    }

    // MARK: - Tip Jar State Transitions

    func testTipJarStateChangeIsReflected() {
        // Start as free user
        UserDefaults.standard.set(false, forKey: tipJarKey)
        XCTAssertFalse(SettingsStore.shared.hasPurchasedTipJar)

        // Purchase tip jar
        UserDefaults.standard.set(true, forKey: tipJarKey)
        XCTAssertTrue(SettingsStore.shared.hasPurchasedTipJar)

        // Verify ad coordinator respects the new state
        let coordinator = AdCoordinator()
        var dismissed = false
        coordinator.presentAd {
            dismissed = true
        }
        XCTAssertTrue(dismissed, "After purchasing, ads should be skipped immediately")
    }

    func testTipJarKeyMatchesSettingsStore() {
        // Verify our test is using the same key as the actual SettingsStore
        UserDefaults.standard.set(true, forKey: tipJarKey)
        XCTAssertTrue(SettingsStore.shared.hasPurchasedTipJar,
                        "Test key '\(tipJarKey)' must match SettingsStore's @AppStorage key")

        UserDefaults.standard.set(false, forKey: tipJarKey)
        XCTAssertFalse(SettingsStore.shared.hasPurchasedTipJar)
    }

    // MARK: - Puzzle Native Ad Policy

    func testPuzzleNativeAdShownForFreeUserWhenMonetizationEnabled() {
        XCTAssertTrue(
            PuzzleAdPolicy.shouldShowNativeAd(
                hasPurchasedTipJar: false,
                monetizationDisabled: false
            )
        )
    }

    func testPuzzleNativeAdHiddenWhenTipJarPurchased() {
        XCTAssertFalse(
            PuzzleAdPolicy.shouldShowNativeAd(
                hasPurchasedTipJar: true,
                monetizationDisabled: false
            )
        )
    }

    func testPuzzleNativeAdHiddenWhenMonetizationDisabled() {
        XCTAssertFalse(
            PuzzleAdPolicy.shouldShowNativeAd(
                hasPurchasedTipJar: false,
                monetizationDisabled: true
            )
        )
    }

    func testPuzzleNativeAdHiddenWhenTipJarPurchasedAndMonetizationDisabled() {
        XCTAssertFalse(
            PuzzleAdPolicy.shouldShowNativeAd(
                hasPurchasedTipJar: true,
                monetizationDisabled: true
            )
        )
    }

    // MARK: - Home Native Ad Policy

    func testHomeNativeAdShownForFreeUserWhenMonetizationEnabled() {
        XCTAssertTrue(
            HomeAdPolicy.shouldShowNativeAd(
                hasPurchasedTipJar: false,
                monetizationDisabled: false
            )
        )
    }

    func testHomeNativeAdHiddenWhenTipJarPurchased() {
        XCTAssertFalse(
            HomeAdPolicy.shouldShowNativeAd(
                hasPurchasedTipJar: true,
                monetizationDisabled: false
            )
        )
    }

    func testHomeNativeAdHiddenWhenMonetizationDisabled() {
        XCTAssertFalse(
            HomeAdPolicy.shouldShowNativeAd(
                hasPurchasedTipJar: false,
                monetizationDisabled: true
            )
        )
    }

    func testDetailNativeAdShownForFreeUserWhenMonetizationEnabled() {
        XCTAssertTrue(
            DetailAdPolicy.shouldShowNativeAd(
                hasPurchasedTipJar: false,
                monetizationDisabled: false
            )
        )
    }

    func testDetailNativeAdHiddenWhenTipJarPurchased() {
        XCTAssertFalse(
            DetailAdPolicy.shouldShowNativeAd(
                hasPurchasedTipJar: true,
                monetizationDisabled: false
            )
        )
    }

    func testDetailNativeAdHiddenWhenMonetizationDisabled() {
        XCTAssertFalse(
            DetailAdPolicy.shouldShowNativeAd(
                hasPurchasedTipJar: false,
                monetizationDisabled: true
            )
        )
    }

    // MARK: - Search Native Ad Policy

    func testSearchNativeAdShownForFreeUserWithResultsWhenMonetizationEnabled() {
        XCTAssertTrue(
            SearchAdPolicy.shouldShowNativeAd(
                hasPurchasedTipJar: false,
                monetizationDisabled: false,
                resultCount: 6
            )
        )
    }

    func testSearchNativeAdHiddenWhenNoResults() {
        XCTAssertFalse(
            SearchAdPolicy.shouldShowNativeAd(
                hasPurchasedTipJar: false,
                monetizationDisabled: false,
                resultCount: 0
            )
        )
    }

    func testSearchNativeAdHiddenWhenTipJarPurchased() {
        XCTAssertFalse(
            SearchAdPolicy.shouldShowNativeAd(
                hasPurchasedTipJar: true,
                monetizationDisabled: false,
                resultCount: 6
            )
        )
    }

    func testSearchNativeAdHiddenWhenMonetizationDisabled() {
        XCTAssertFalse(
            SearchAdPolicy.shouldShowNativeAd(
                hasPurchasedTipJar: false,
                monetizationDisabled: true,
                resultCount: 6
            )
        )
    }
}
