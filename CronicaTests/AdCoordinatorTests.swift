import XCTest
import UIKit
@testable import Cronica
import GoogleMobileAds

// MARK: - Mocks

private struct MockAdSettings: AdSettingsProviding {
    var hasPurchasedTipJar: Bool
}

private final class MockPresentableAd: PresentableAd {
    var presentCalled = false
    var presentedFromVC: UIViewController?

    func present(from viewController: UIViewController?) {
        presentCalled = true
        presentedFromVC = viewController
    }
}

private final class MockAdLoader: InterstitialAdLoading {
    var adToReturn: PresentableAd?
    var loadCallCount = 0

    func load(delegate: AdCoordinator, completion: @escaping (PresentableAd?) -> Void) {
        loadCallCount += 1
        completion(adToReturn)
    }
}

private final class MockRewardedAdLoader: RewardedAdLoading {
    var adToReturn: RewardedAd?
    var loadCallCount = 0

    func load(completion: @escaping (RewardedAd?) -> Void) {
        loadCallCount += 1
        completion(adToReturn)
    }
}

private final class MockAppOpenAdLoader: AppOpenAdLoading {
    var adToReturn: AppOpenPresentableAd?
    var loadCallCount = 0

    func load(completion: @escaping (AppOpenPresentableAd?) -> Void) {
        loadCallCount += 1
        completion(adToReturn)
    }
}

private final class MockAppOpenAd: AppOpenPresentableAd {
    var presentCalled = false
    var presentedFromVC: UIViewController?
    var fullScreenContentDelegate: FullScreenContentDelegate?

    func present(from viewController: UIViewController?) {
        presentCalled = true
        presentedFromVC = viewController
    }
}

private final class MockRootVCProvider: RootViewControllerProviding {
    var vc: UIViewController?

    func rootViewController() -> UIViewController? {
        return vc
    }
}

private final class AdLifecycleTrackerSpy: AdLifecycleTracking {
    private(set) var events = [AdLifecycleEvent]()

    func track(_ event: AdLifecycleEvent) {
        events.append(event)
    }

    func removeAllEvents() {
        events.removeAll()
    }
}

// MARK: - Helper

private enum TestError: Error {
    case mockFailure
}

// MARK: - Tests

final class AdCoordinatorTests: XCTestCase {

    private var mockSettings: MockAdSettings!
    private var mockLoader: MockAdLoader!
    private var mockRewardedLoader: MockRewardedAdLoader!
    private var mockAppOpenLoader: MockAppOpenAdLoader!
    private var mockAppOpenAd: MockAppOpenAd!
    private var mockRootVC: MockRootVCProvider!
    private var mockAd: MockPresentableAd!
    private var lifecycleTracker: AdLifecycleTrackerSpy!
    private var coordinator: AdCoordinator!

    override func setUp() {
        super.setUp()
        AdCoordinator.lastPresentationDate = nil
        AdCoordinator.lastAppOpenDate = nil

        mockSettings = MockAdSettings(hasPurchasedTipJar: false)
        mockAd = MockPresentableAd()
        mockLoader = MockAdLoader()
        mockLoader.adToReturn = mockAd
        mockRewardedLoader = MockRewardedAdLoader()
        mockAppOpenLoader = MockAppOpenAdLoader()
        mockAppOpenAd = MockAppOpenAd()
        mockAppOpenLoader.adToReturn = mockAppOpenAd
        mockRootVC = MockRootVCProvider()
        mockRootVC.vc = UIViewController()
        lifecycleTracker = AdLifecycleTrackerSpy()

        coordinator = AdCoordinator(
            settings: mockSettings,
            adLoader: mockLoader,
            rewardedAdLoader: mockRewardedLoader,
            appOpenAdLoader: mockAppOpenLoader,
            rootVCProvider: mockRootVC,
            lifecycleTracker: lifecycleTracker
        )
    }

    override func tearDown() {
        AdCoordinator.lastPresentationDate = nil
        AdCoordinator.lastAppOpenDate = nil
        coordinator = nil
        mockSettings = nil
        mockLoader = nil
        mockRewardedLoader = nil
        mockAppOpenLoader = nil
        mockAppOpenAd = nil
        mockRootVC = nil
        mockAd = nil
        lifecycleTracker = nil
        super.tearDown()
    }

    // MARK: - Ad Loading

    func testInitLoadsAd() {
        // loadAd() is called during init
        XCTAssertEqual(mockLoader.loadCallCount, 1, "Should load an ad on init")
    }

    func testLoadAdSkippedWhenTipJarPurchased() {
        let paidSettings = MockAdSettings(hasPurchasedTipJar: true)
        let paidLoader = MockAdLoader()

        _ = AdCoordinator(
            settings: paidSettings,
            adLoader: paidLoader,
            rewardedAdLoader: mockRewardedLoader,
            appOpenAdLoader: mockAppOpenLoader,
            rootVCProvider: mockRootVC
        )

        XCTAssertEqual(paidLoader.loadCallCount, 0,
                        "Should not load ads for tip jar purchasers")
    }

    func testLoadAdCallsLoaderWhenFreeUser() {
        XCTAssertEqual(mockLoader.loadCallCount, 1)
        coordinator.loadAd()
        XCTAssertEqual(mockLoader.loadCallCount, 2,
                        "Calling loadAd again should invoke the loader")
    }

    func testLoadAdSetsInterstitial() {
        XCTAssertNotNil(coordinator.interstitial,
                        "Interstitial should be set after mock loader completes")
    }

    func testLoadAdWithNilAdResult() {
        mockLoader.adToReturn = nil
        coordinator.loadAd()
        // interstitial should now be nil from the second load
        // (first load in init set it to mockAd, second load sets it to nil)
        XCTAssertNil(coordinator.interstitial,
                     "Interstitial should be nil when loader returns nil")
    }

    // MARK: - Ad Presentation (Happy Path)

    func testPresentCallsPresentOnAd() {
        coordinator.presentAd()
        XCTAssertTrue(mockAd.presentCalled,
                      "Should call present(from:) on the loaded ad")
    }

    func testPresentPassesRootViewController() {
        let expectedVC = mockRootVC.vc
        coordinator.presentAd()
        XCTAssertTrue(mockAd.presentedFromVC === expectedVC,
                      "Should present from the root VC provided by the rootVCProvider")
    }

    func testPresentSetsLastPresentationDate() {
        XCTAssertNil(AdCoordinator.lastPresentationDate)
        coordinator.presentAd()
        XCTAssertNotNil(AdCoordinator.lastPresentationDate,
                        "Should set lastPresentationDate when presenting")
    }

    func testPresentDoesNotFireOnDismissImmediately() {
        // When ad actually presents, onDismiss should wait for dismissal
        var dismissed = false
        coordinator.presentAd {
            dismissed = true
        }
        XCTAssertFalse(dismissed,
                       "onDismiss should NOT fire immediately when ad is shown — waits for dismiss delegate")
    }

    // MARK: - Tip Jar Gating

    func testPresentSkipsAdWhenTipJarPurchased() {
        let paidSettings = MockAdSettings(hasPurchasedTipJar: true)
        let paidLoader = MockAdLoader()
        let paidAd = MockPresentableAd()
        paidLoader.adToReturn = paidAd

        let paidCoordinator = AdCoordinator(
            settings: paidSettings,
            adLoader: paidLoader,
            rewardedAdLoader: mockRewardedLoader,
            appOpenAdLoader: mockAppOpenLoader,
            rootVCProvider: mockRootVC
        )

        var dismissed = false
        paidCoordinator.presentAd {
            dismissed = true
        }

        XCTAssertFalse(paidAd.presentCalled,
                       "Ad should NOT be presented for tip jar purchasers")
        XCTAssertTrue(dismissed,
                      "onDismiss should fire immediately when tip jar is purchased")
    }

    func testPresentCallsOnDismissImmediatelyWhenTipJarPurchased() {
        let paidSettings = MockAdSettings(hasPurchasedTipJar: true)
        let paidCoordinator = AdCoordinator(
            settings: paidSettings,
            adLoader: mockLoader,
            rewardedAdLoader: mockRewardedLoader,
            appOpenAdLoader: mockAppOpenLoader,
            rootVCProvider: mockRootVC
        )

        var dismissed = false
        paidCoordinator.presentAd {
            dismissed = true
        }
        XCTAssertTrue(dismissed)
    }

    // MARK: - Frequency Capping

    func testPresentAllowsAdWhenTimestampWasJustRecorded() {
        AdCoordinator.lastPresentationDate = Date()

        coordinator.presentAd()

        XCTAssertTrue(mockAd.presentCalled,
                      "Interstitials should not be blocked by a cooldown timestamp")
    }

    func testPresentAllowsAdAfterCooldownExpires() {
        AdCoordinator.lastPresentationDate = Date().addingTimeInterval(
            -(AdConfiguration.interstitialCooldown + 1)
        )

        coordinator.presentAd()
        XCTAssertTrue(mockAd.presentCalled,
                      "Ad should present after cooldown has expired")
    }

    func testMultipleRapidPresentCallsCanPresentBackToBackWhenReloaded() {
        // First call presents the ad
        coordinator.presentAd()
        XCTAssertTrue(mockAd.presentCalled)

        // lastPresentationDate is now set by the first call
        let secondAd = MockPresentableAd()
        mockLoader.adToReturn = secondAd

        // Simulate a reload (as would happen after dismiss)
        coordinator.loadAd()

        // Second call should also present because cooldown is disabled
        coordinator.presentAd()
        XCTAssertTrue(secondAd.presentCalled,
                      "Second ad should present when eligible inventory is available")
    }

    // MARK: - No Ad / No Root VC

    func testPresentCallsOnDismissWhenNoAdLoaded() {
        mockLoader.adToReturn = nil
        // Create a new coordinator with nil ad
        let noAdCoordinator = AdCoordinator(
            settings: mockSettings,
            adLoader: mockLoader,
            rewardedAdLoader: mockRewardedLoader,
            appOpenAdLoader: mockAppOpenLoader,
            rootVCProvider: mockRootVC
        )

        var dismissed = false
        noAdCoordinator.presentAd {
            dismissed = true
        }
        XCTAssertTrue(dismissed,
                      "onDismiss should fire when no ad is loaded")
    }

    func testPresentWhenNoAdLoadedTriggersReloadAttempt() {
        mockLoader.adToReturn = nil
        let noAdCoordinator = AdCoordinator(
            settings: mockSettings,
            adLoader: mockLoader,
            rewardedAdLoader: mockRewardedLoader,
            appOpenAdLoader: mockAppOpenLoader,
            rootVCProvider: mockRootVC
        )

        let loadCountBeforePresent = mockLoader.loadCallCount
        noAdCoordinator.presentAd()

        XCTAssertEqual(
            mockLoader.loadCallCount,
            loadCountBeforePresent + 1,
            "Missing interstitial should trigger an immediate reload attempt so the session can recover."
        )
    }

    func testPresentCallsOnDismissWhenNoRootVC() {
        mockRootVC.vc = nil

        var dismissed = false
        coordinator.presentAd {
            dismissed = true
        }
        XCTAssertTrue(dismissed,
                      "onDismiss should fire when no root VC is available")
        XCTAssertFalse(mockAd.presentCalled,
                       "Ad should NOT present without a root VC")
    }

    func testPresentWithNilOnDismissDoesNotCrash() {
        coordinator.presentAd(onDismiss: nil)
    }

    func testPresentWithoutOnDismissDoesNotCrash() {
        coordinator.presentAd()
    }

    // MARK: - handleAdDismissed (Delegate Path)

    func testHandleAdDismissedFiresOnDismiss() {
        var dismissed = false
        coordinator.onDismiss = {
            dismissed = true
        }

        coordinator.handleAdDismissed()
        XCTAssertTrue(dismissed, "handleAdDismissed should fire the onDismiss callback")
    }

    func testHandleAdDismissedNilsOnDismiss() {
        coordinator.onDismiss = {}
        coordinator.handleAdDismissed()
        XCTAssertNil(coordinator.onDismiss,
                     "onDismiss should be nil after handleAdDismissed")
    }

    func testHandleAdDismissedReloadsAd() {
        let countBefore = coordinator.loadAdCallCount
        coordinator.handleAdDismissed()
        XCTAssertEqual(coordinator.loadAdCallCount, countBefore + 1,
                       "handleAdDismissed should trigger a reload")
    }

    func testHandleAdDismissedWithNilOnDismissDoesNotCrash() {
        coordinator.onDismiss = nil
        coordinator.handleAdDismissed()
    }

    // MARK: - handleAdFailedToPresent (Failure Path)

    func testHandleAdFailedToPresentFiresOnDismiss() {
        var dismissed = false
        coordinator.onDismiss = {
            dismissed = true
        }

        coordinator.handleAdFailedToPresent(error: TestError.mockFailure)
        XCTAssertTrue(dismissed,
                      "handleAdFailedToPresent should fire the onDismiss callback")
    }

    func testHandleAdFailedToPresentNilsOnDismiss() {
        coordinator.onDismiss = {}
        coordinator.handleAdFailedToPresent(error: TestError.mockFailure)
        XCTAssertNil(coordinator.onDismiss,
                     "onDismiss should be nil after handleAdFailedToPresent")
    }

    func testHandleAdFailedToPresentReloadsAd() {
        let countBefore = coordinator.loadAdCallCount
        coordinator.handleAdFailedToPresent(error: TestError.mockFailure)
        XCTAssertEqual(coordinator.loadAdCallCount, countBefore + 1,
                       "handleAdFailedToPresent should trigger a reload")
    }

    // MARK: - Full Lifecycle Chain

    func testFullPresentDismissReloadChain() {
        // 1. Initial load during init
        XCTAssertEqual(mockLoader.loadCallCount, 1, "Init should trigger load")
        XCTAssertNotNil(coordinator.interstitial, "Ad should be loaded")

        // 2. Present the ad
        var dismissed = false
        coordinator.presentAd {
            dismissed = true
        }
        XCTAssertTrue(mockAd.presentCalled, "Ad should be presented")
        XCTAssertFalse(dismissed, "onDismiss should NOT fire yet — ad is showing")
        XCTAssertNotNil(AdCoordinator.lastPresentationDate)

        // 3. Simulate ad dismissal (what the Google SDK delegate would call)
        let reloadAd = MockPresentableAd()
        mockLoader.adToReturn = reloadAd

        coordinator.handleAdDismissed()

        // 4. Verify the chain
        XCTAssertTrue(dismissed, "onDismiss should fire after dismissal")
        XCTAssertNil(coordinator.onDismiss, "onDismiss should be cleaned up")
        XCTAssertEqual(mockLoader.loadCallCount, 2, "Dismiss should trigger reload")
    }

    func testFullPresentFailReloadChain() {
        // 1. Present the ad
        var dismissed = false
        coordinator.presentAd {
            dismissed = true
        }
        XCTAssertTrue(mockAd.presentCalled)

        // 2. Simulate presentation failure
        let reloadAd = MockPresentableAd()
        mockLoader.adToReturn = reloadAd

        coordinator.handleAdFailedToPresent(error: TestError.mockFailure)

        // 3. Verify the chain
        XCTAssertTrue(dismissed, "onDismiss should fire after failure")
        XCTAssertNil(coordinator.onDismiss, "onDismiss should be cleaned up")
        XCTAssertEqual(mockLoader.loadCallCount, 2, "Failure should trigger reload")
    }

    // MARK: - State Reset

    func testLastPresentationDateStartsNil() {
        AdCoordinator.lastPresentationDate = nil
        XCTAssertNil(AdCoordinator.lastPresentationDate)
    }

    func testCooldownCalculation() {
        let cooldown = AdConfiguration.interstitialCooldown
        let currentDate = Date()

        XCTAssertGreaterThanOrEqual(Date().timeIntervalSince(currentDate), cooldown,
                                    "With cooldown disabled, immediate repeat presentation should remain eligible")
    }

    // MARK: - onDismiss Cleanup

    func testOnDismissIsNilledAfterPresentWithNoAd() {
        mockLoader.adToReturn = nil
        let noAdCoordinator = AdCoordinator(
            settings: mockSettings,
            adLoader: mockLoader,
            rewardedAdLoader: mockRewardedLoader,
            appOpenAdLoader: mockAppOpenLoader,
            rootVCProvider: mockRootVC
        )

        noAdCoordinator.presentAd { }
        XCTAssertNil(noAdCoordinator.onDismiss,
                     "onDismiss should be nil after the no-ad fallback path")
    }

    // MARK: - Rewarded Ad Loading

    func testLoadRewardedAdCallsLoader() {
        coordinator.loadRewardedAd()
        XCTAssertEqual(mockRewardedLoader.loadCallCount, 1,
                       "loadRewardedAd should invoke the rewarded ad loader")
    }

    func testLoadRewardedAdSkippedWhenTipJarPurchased() {
        let paidSettings = MockAdSettings(hasPurchasedTipJar: true)
        let paidRewardedLoader = MockRewardedAdLoader()

        let paidCoordinator = AdCoordinator(
            settings: paidSettings,
            adLoader: mockLoader,
            rewardedAdLoader: paidRewardedLoader,
            appOpenAdLoader: mockAppOpenLoader,
            rootVCProvider: mockRootVC
        )

        paidCoordinator.loadRewardedAd()
        XCTAssertEqual(paidRewardedLoader.loadCallCount, 0,
                        "Should not load rewarded ads for tip jar purchasers")
    }

    func testEnsureRewardedAdLoadedCallsLoaderWhenNil() {
        XCTAssertNil(coordinator.rewardedAd)
        coordinator.ensureRewardedAdLoaded()
        XCTAssertEqual(mockRewardedLoader.loadCallCount, 1)
    }

    func testPresentRewardedAdSkippedWhenTipJarPurchased() {
        let paidSettings = MockAdSettings(hasPurchasedTipJar: true)
        let paidCoordinator = AdCoordinator(
            settings: paidSettings,
            adLoader: mockLoader,
            rewardedAdLoader: mockRewardedLoader,
            appOpenAdLoader: mockAppOpenLoader,
            rootVCProvider: mockRootVC
        )

        var rewarded = false
        paidCoordinator.presentRewardedAd {
            rewarded = true
        }
        XCTAssertFalse(rewarded,
                       "Reward callback should NOT fire for tip jar purchasers")
    }

    func testPresentRewardedAdTriggersLoadWhenNoAdAvailable() {
        XCTAssertNil(coordinator.rewardedAd)
        coordinator.presentRewardedAd {}
        XCTAssertEqual(mockRewardedLoader.loadCallCount, 1,
                       "Should trigger load when no rewarded ad is available")
    }

    func testPresentHintAdFallsBackToInterstitialWhenRewardedUnavailable() {
        XCTAssertNil(coordinator.rewardedAd)

        var hintUnlocked = false
        coordinator.presentHintAd {
            hintUnlocked = true
        }

        XCTAssertTrue(mockAd.presentCalled,
                      "Hint flow should fall back to interstitial when rewarded ad is unavailable")
        XCTAssertFalse(hintUnlocked,
                       "Hint should unlock only after the fallback interstitial is dismissed")

        coordinator.handleHintInterstitialDismissed()
        XCTAssertTrue(hintUnlocked,
                      "Hint should unlock after fallback interstitial dismissal")
    }

    func testPresentHintAdDoesNotUnlockHintWhenNoAdIsAvailable() {
        let noAdLoader = MockAdLoader()
        noAdLoader.adToReturn = nil
        let noRewardedLoader = MockRewardedAdLoader()
        let noAdCoordinator = AdCoordinator(
            settings: mockSettings,
            adLoader: noAdLoader,
            rewardedAdLoader: noRewardedLoader,
            appOpenAdLoader: mockAppOpenLoader,
            rootVCProvider: mockRootVC
        )

        var hintUnlocked = false
        noAdCoordinator.presentHintAd {
            hintUnlocked = true
        }

        XCTAssertFalse(hintUnlocked,
                       "Hint should not unlock when neither rewarded nor interstitial ad is available")
        XCTAssertEqual(noRewardedLoader.loadCallCount, 1,
                       "Hint flow should request rewarded inventory when unavailable")
    }

    func testPresentHintAdAutoPresentsWhenInterstitialLoadsAfterTap() {
        let delayedAdLoader = MockAdLoader()
        delayedAdLoader.adToReturn = nil
        let noRewardedLoader = MockRewardedAdLoader()
        noRewardedLoader.adToReturn = nil
        let delayedCoordinator = AdCoordinator(
            settings: mockSettings,
            adLoader: delayedAdLoader,
            rewardedAdLoader: noRewardedLoader,
            appOpenAdLoader: mockAppOpenLoader,
            rootVCProvider: mockRootVC
        )

        var hintUnlocked = false
        delayedCoordinator.presentHintAd {
            hintUnlocked = true
        }

        XCTAssertFalse(hintUnlocked, "Hint should not unlock before ad is shown/dismissed")

        let interstitial = MockPresentableAd()
        delayedAdLoader.adToReturn = interstitial
        delayedCoordinator.loadAd()

        XCTAssertTrue(interstitial.presentCalled,
                      "Queued hint request should present once interstitial inventory arrives")
        XCTAssertFalse(hintUnlocked, "Hint should unlock on dismissal, not presentation")

        delayedCoordinator.handleHintInterstitialDismissed()
        XCTAssertTrue(hintUnlocked, "Hint should unlock after fallback interstitial dismissal")
    }

    // MARK: - App Open Ad Loading

    func testLoadAppOpenAdCallsLoader() {
        coordinator.loadAppOpenAd()
        XCTAssertEqual(mockAppOpenLoader.loadCallCount, 1,
                       "loadAppOpenAd should invoke the app open ad loader")
    }

    func testLoadAppOpenAdTracksRequestAndLoadedOutcome() {
        lifecycleTracker.removeAllEvents()

        coordinator.loadAppOpenAd()

        XCTAssertTrue(lifecycleTracker.events.contains(.init(
            placement: "app_open",
            action: "load",
            outcome: "requested"
        )))
        XCTAssertTrue(lifecycleTracker.events.contains(.init(
            placement: "app_open",
            action: "load",
            outcome: "loaded"
        )))
    }

    func testLoadAppOpenAdSkippedWhenTipJarPurchased() {
        let paidSettings = MockAdSettings(hasPurchasedTipJar: true)
        let paidAppOpenLoader = MockAppOpenAdLoader()

        let paidCoordinator = AdCoordinator(
            settings: paidSettings,
            adLoader: mockLoader,
            rewardedAdLoader: mockRewardedLoader,
            appOpenAdLoader: paidAppOpenLoader,
            rootVCProvider: mockRootVC
        )

        paidCoordinator.loadAppOpenAd()
        XCTAssertEqual(paidAppOpenLoader.loadCallCount, 0,
                        "Should not load app open ads for tip jar purchasers")
    }

    func testPresentAppOpenAdSkippedWhenTipJarPurchased() {
        let paidSettings = MockAdSettings(hasPurchasedTipJar: true)
        let paidCoordinator = AdCoordinator(
            settings: paidSettings,
            adLoader: mockLoader,
            rewardedAdLoader: mockRewardedLoader,
            appOpenAdLoader: mockAppOpenLoader,
            rootVCProvider: mockRootVC
        )

        paidCoordinator.presentAppOpenAd()
        // No crash, no presentation
    }

    func testPresentAppOpenAdPresentsLoadedAdImmediately() {
        lifecycleTracker.removeAllEvents()
        coordinator.loadAppOpenAd()
        coordinator.presentAppOpenAd()

        XCTAssertTrue(mockAppOpenAd.presentCalled,
                      "Loaded app open inventory should present immediately")
        XCTAssertTrue(mockAppOpenAd.presentedFromVC === mockRootVC.vc,
                      "App open ads should present from the root view controller")
        XCTAssertNil(coordinator.appOpenAd,
                     "App open inventory should be consumed after presentation because Google ad objects are single-use.")
        XCTAssertNotNil(AdCoordinator.lastAppOpenDate)
        XCTAssertTrue(lifecycleTracker.events.contains(.init(
            placement: "app_open",
            action: "present",
            outcome: "attempted"
        )))
        XCTAssertTrue(lifecycleTracker.events.contains(.init(
            placement: "app_open",
            action: "present",
            outcome: "presented"
        )))
    }

    func testPresentAppOpenAdIgnoresPreviousForegroundTimestamp() {
        AdCoordinator.lastAppOpenDate = Date()
        coordinator.loadAppOpenAd()
        coordinator.presentAppOpenAd()

        XCTAssertTrue(mockAppOpenAd.presentCalled,
                      "App open presentation should not be blocked by a cooldown timestamp")
    }

    func testPresentAppOpenAdAutoPresentsWhenLoadCompletesAfterForegroundRequest() {
        let delayedLoader = MockAppOpenAdLoader()
        delayedLoader.adToReturn = nil
        let delayedCoordinator = AdCoordinator(
            settings: mockSettings,
            adLoader: mockLoader,
            rewardedAdLoader: mockRewardedLoader,
            appOpenAdLoader: delayedLoader,
            rootVCProvider: mockRootVC
        )

        let delayedAd = MockAppOpenAd()

        delayedCoordinator.presentAppOpenAd()
        XCTAssertEqual(delayedLoader.loadCallCount, 1,
                       "Missing app open inventory should trigger a load")

        delayedLoader.adToReturn = delayedAd
        delayedCoordinator.loadAppOpenAd()

        XCTAssertTrue(delayedAd.presentCalled,
                      "A pending app open request should present as soon as inventory loads")
        XCTAssertNil(delayedCoordinator.appOpenAd,
                     "Auto-presented app open inventory should be consumed immediately.")
    }

    func testPresentAppOpenAdDoesNotReuseCurrentlyPresentingAd() {
        lifecycleTracker.removeAllEvents()
        coordinator.loadAppOpenAd()

        coordinator.presentAppOpenAd()
        coordinator.presentAppOpenAd()

        XCTAssertEqual(
            lifecycleTracker.events.filter {
                $0.placement == "app_open" && $0.action == "present" && $0.outcome == "presented"
            }.count,
            1
        )
        XCTAssertTrue(lifecycleTracker.events.contains(.init(
            placement: "app_open",
            action: "present",
            outcome: "already_presenting"
        )))
    }

    func testPresentAppOpenAdTracksMissingRootViewController() {
        lifecycleTracker.removeAllEvents()
        mockRootVC.vc = nil
        coordinator.loadAppOpenAd()

        coordinator.presentAppOpenAd()

        XCTAssertFalse(mockAppOpenAd.presentCalled)
        XCTAssertTrue(lifecycleTracker.events.contains(.init(
            placement: "app_open",
            action: "present",
            outcome: "no_root_view_controller"
        )))
    }

    func testLastAppOpenDateStartsNil() {
        XCTAssertNil(AdCoordinator.lastAppOpenDate)
    }

    func testAppOpenCooldownCalculation() {
        let cooldown = AdConfiguration.appOpenCooldown
        let currentDate = Date()

        XCTAssertGreaterThanOrEqual(Date().timeIntervalSince(currentDate), cooldown,
                                    "With cooldown disabled, immediate foreground returns should remain eligible")
    }
}
