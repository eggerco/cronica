//
//  SentryManager.swift
//  Cronica
//

import Foundation
import Sentry

enum SentryManager {
    /// Query keys that must never leave the device via crash/performance telemetry.
    private static let sensitiveQueryKeys: Set<String> = [
        "session_id",
        "api_key",
        "access_token",
        "client_secret"
    ]

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
            options.beforeSend = { event in
                scrub(event: event)
                return event
            }
            options.beforeBreadcrumb = { breadcrumb in
                scrub(breadcrumb: breadcrumb)
                return breadcrumb
            }
            options.beforeSendSpan = { span in
                scrub(span: span)
                return span
            }
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

    // MARK: - Scrubbing helpers (callable from tests)

    /// Redacts sensitive `name=value` pairs in a raw query string.
    static func redactedQueryString(_ query: String?) -> String? {
        guard let query, !query.isEmpty else { return query }
        return query.split(separator: "&", omittingEmptySubsequences: false).map { pair -> String in
            let parts = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            guard let namePart = parts.first else { return String(pair) }
            let name = String(namePart)
            if sensitiveQueryKeys.contains(name.lowercased()) {
                return "\(name)=[Filtered]"
            }
            return String(pair)
        }.joined(separator: "&")
    }

    /// Redacts sensitive query parameters in an absolute URL string.
    static func redactedURLString(_ urlString: String?) -> String? {
        guard let urlString, !urlString.isEmpty else { return urlString }
        guard let question = urlString.firstIndex(of: "?") else { return urlString }
        let head = urlString[..<question]
        let queryStart = urlString.index(after: question)
        let query = String(urlString[queryStart...])
        guard let redacted = redactedQueryString(query) else { return urlString }
        return "\(head)?\(redacted)"
    }

#if !DEBUG
    private static func scrub(event: Event) {
        if let request = event.request {
            if let url = request.url {
                request.url = redactedURLString(url)
            }
            if let query = request.queryString {
                request.queryString = redactedQueryString(query)
            }
        }
        if let breadcrumbs = event.breadcrumbs {
            for breadcrumb in breadcrumbs {
                scrub(breadcrumb: breadcrumb)
            }
        }
    }

    private static func scrub(breadcrumb: Breadcrumb) {
        guard var data = breadcrumb.data else { return }
        if let url = data["url"] as? String {
            data["url"] = redactedURLString(url) ?? url
        }
        if let query = data["http.query"] as? String {
            data["http.query"] = redactedQueryString(query) ?? query
        }
        breadcrumb.data = data
    }

    private static func scrub(span: any Span) {
        if let query = span.data["http.query"] as? String {
            span.setData(value: redactedQueryString(query), key: "http.query")
        }
        if let url = span.data["url"] as? String {
            span.setData(value: redactedURLString(url), key: "url")
        }
        if let url = span.data["http.url"] as? String {
            span.setData(value: redactedURLString(url), key: "http.url")
        }
    }
#endif
}
