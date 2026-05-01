import Foundation
import GoogleMobileAds
#if os(iOS)
import AppTrackingTransparency
import UserMessagingPlatform
#endif

/// Manages UMP consent and ATT authorization for ad requests.
enum AdConsentManager {
#if os(iOS)
    /// Request UMP consent info update, present the consent form if needed, then request ATT.
    /// Call this once at app launch to keep consent state current.
    static func gatherConsent(from viewController: UIViewController) async {
        // 1. Update UMP consent information
        let parameters = RequestParameters()
        parameters.isTaggedForUnderAgeOfConsent = false

        do {
            try await ConsentInformation.shared.requestConsentInfoUpdate(with: parameters)
        } catch {
            print("[AdConsentManager] UMP info update failed: \(error.localizedDescription)")
        }

        // 2. Load and present consent form if required
        do {
            try await ConsentForm.loadAndPresentIfRequired(from: viewController)
        } catch {
            print("[AdConsentManager] UMP form error: \(error.localizedDescription)")
        }

        // 3. Request ATT authorization (has no effect if user already responded)
        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            _ = await ATTrackingManager.requestTrackingAuthorization()
        }
    }

    /// Whether we can serve personalized ads based on current consent status.
    static var canRequestAds: Bool {
        ConsentInformation.shared.canRequestAds
    }
#endif
}
