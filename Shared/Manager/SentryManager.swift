//
//  SentryManager.swift
//  Cronica
//

import Foundation
import Sentry

enum SentryManager {
    static func setup() {
#if DEBUG
        return
#else
        guard let dsn = Key.sentryDSN, !dsn.isEmpty else { return }
        SentrySDK.start { options in
            options.dsn = dsn
            options.enableAutoSessionTracking = true
            options.enableCaptureFailedRequests = true
            options.tracesSampleRate = 0.2
            options.environment = Bundle.main.bundleIdentifier ?? "production"
            options.releaseName = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        }
#endif
    }

    static func capture(_ error: Error, context: [String: String] = [:]) {
#if !DEBUG
        guard Key.sentryDSN != nil else { return }
        SentrySDK.capture(error: error) { scope in
            for (key, value) in context {
                scope.setExtra(value: value, key: key)
            }
        }
#endif
    }

    static func captureMessage(_ message: String, level: SentryLevel = .warning) {
#if !DEBUG
        guard Key.sentryDSN != nil else { return }
        SentrySDK.capture(message: message) { scope in
            scope.setLevel(level)
        }
#endif
    }
}
