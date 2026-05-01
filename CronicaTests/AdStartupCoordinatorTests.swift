import XCTest
import UIKit
@testable import Cronica

final class AdStartupCoordinatorTests: XCTestCase {

    func testStartAdsPreloadsBeforeConsentCompletes() async {
        let mobileAds = MobileAdsStarterSpy()
        let consent = ConsentGathererSpy()
        consent.shouldSuspend = true
        let preloader = AdPreloaderSpy()

        let coordinator = AdStartupCoordinator(
            mobileAdsStarter: mobileAds,
            consentGatherer: consent,
            adPreloader: preloader
        )

        let task = Task {
            await coordinator.startAdsIfNeeded(
                monetizationDisabled: false,
                rootViewController: UIViewController()
            )
        }

        for _ in 0..<20 where mobileAds.startCallCount == 0 || preloader.preloadCallCount == 0 || consent.gatherCallCount == 0 {
            try? await Task.sleep(for: .milliseconds(10))
        }

        XCTAssertEqual(mobileAds.startCallCount, 1, "Mobile Ads should start immediately")
        XCTAssertEqual(preloader.preloadCallCount, 1, "Ad preloading should not wait on consent")
        XCTAssertEqual(consent.gatherCallCount, 1, "Consent should still be gathered when a root view controller is available")

        task.cancel()
    }

    func testStartAdsSkipsAllWorkWhenMonetizationDisabled() async {
        let mobileAds = MobileAdsStarterSpy()
        let consent = ConsentGathererSpy()
        let preloader = AdPreloaderSpy()

        let coordinator = AdStartupCoordinator(
            mobileAdsStarter: mobileAds,
            consentGatherer: consent,
            adPreloader: preloader
        )

        await coordinator.startAdsIfNeeded(
            monetizationDisabled: true,
            rootViewController: nil
        )

        XCTAssertEqual(mobileAds.startCallCount, 0)
        XCTAssertEqual(preloader.preloadCallCount, 0)
        XCTAssertEqual(consent.gatherCallCount, 0)
    }

    func testSharedPreloaderRequestsOnlyLaunchVisibleInventory() async {
        let adCoordinator = AdPreloadCoordinatorSpy()
        let preloader = SharedAdPreloader(adCoordinator: adCoordinator)

        await preloader.preloadAds()

        XCTAssertEqual(adCoordinator.loadInterstitialCallCount, 1)
        XCTAssertEqual(adCoordinator.loadAppOpenCallCount, 1)
        XCTAssertEqual(
            adCoordinator.loadRewardedCallCount,
            0,
            "Rewarded ads should be requested when the hint surface is visible, not on every app launch."
        )
    }

    func testForegroundCoordinatorPresentsLaunchVisibleAdsWhenMonetizationEnabled() {
        let presenter = AdForegroundPresenterSpy()
        let coordinator = AdForegroundPresentationCoordinator(adPresenter: presenter)

        coordinator.presentForegroundAdsIfNeeded(monetizationDisabled: false)

        XCTAssertEqual(presenter.ensureInterstitialLoadedCallCount, 1)
        XCTAssertEqual(presenter.presentAppOpenAdCallCount, 1)
    }

    func testForegroundCoordinatorSkipsWorkWhenMonetizationDisabled() {
        let presenter = AdForegroundPresenterSpy()
        let coordinator = AdForegroundPresentationCoordinator(adPresenter: presenter)

        coordinator.presentForegroundAdsIfNeeded(monetizationDisabled: true)

        XCTAssertEqual(presenter.ensureInterstitialLoadedCallCount, 0)
        XCTAssertEqual(presenter.presentAppOpenAdCallCount, 0)
    }
}

private final class MobileAdsStarterSpy: MobileAdsStarting {
    private(set) var startCallCount = 0

    func start() async {
        startCallCount += 1
    }
}

private final class ConsentGathererSpy: AdConsentGathering {
    private(set) var gatherCallCount = 0
    var shouldSuspend = false

    func gatherConsentIfPossible(from viewController: UIViewController?) async {
        gatherCallCount += 1
        if shouldSuspend {
            try? await Task.sleep(for: .seconds(5))
        }
    }
}

private final class AdPreloaderSpy: AdPreloading {
    private(set) var preloadCallCount = 0

    func preloadAds() async {
        preloadCallCount += 1
    }
}

private final class AdPreloadCoordinatorSpy: AdPreloadCoordinating {
    private(set) var loadInterstitialCallCount = 0
    private(set) var loadRewardedCallCount = 0
    private(set) var loadAppOpenCallCount = 0

    func loadAd() {
        loadInterstitialCallCount += 1
    }

    func loadRewardedAd() {
        loadRewardedCallCount += 1
    }

    func loadAppOpenAd() {
        loadAppOpenCallCount += 1
    }
}

private final class AdForegroundPresenterSpy: AdForegroundPresenting {
    private(set) var ensureInterstitialLoadedCallCount = 0
    private(set) var presentAppOpenAdCallCount = 0

    func ensureInterstitialLoaded() {
        ensureInterstitialLoadedCallCount += 1
    }

    func presentAppOpenAd() {
        presentAppOpenAdCallCount += 1
    }
}
