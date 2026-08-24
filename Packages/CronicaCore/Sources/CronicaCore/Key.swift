//
//  Key.swift
//  Cronica
//

import Foundation

/// API keys loaded from build settings (Secrets.xcconfig) or CI environment variables.
public struct Key {
    private static func configurationValue(for key: String) -> String {
        if let env = ProcessInfo.processInfo.environment[key], !env.isEmpty {
            return env
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
           !value.isEmpty,
           !value.hasPrefix("$(") {
            return value
        }
        return ""
    }

    public static let tmdbApi = configurationValue(for: "TMDB_API_KEY")
    public static let sentryDSN: String? = {
        let dsn = configurationValue(for: "SENTRY_DSN")
        return dsn.isEmpty ? nil : dsn
    }()

    public static var isConfigured: Bool {
        !tmdbApi.isEmpty
    }
}
