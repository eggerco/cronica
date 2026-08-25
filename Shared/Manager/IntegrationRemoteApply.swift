//
//  IntegrationRemoteApply.swift
//  Cronica
//

import Foundation

/// Nested, re-entrant guard for SIMKL / TMDB remote → local apply.
///
/// While active, both push queues must refuse enqueue so importing from one
/// service cannot cross-echo into the other when both push toggles are on.
/// Manual user actions (outside this scope) still enqueue normally.
@MainActor
enum IntegrationRemoteApply {
    private static var depth = 0

    static var isApplying: Bool { depth > 0 }

    /// Shared hook used by `SimklPushService` / `TMDBPushService`.
    static var shouldSuppressOutboundPush: Bool { isApplying }

    static func begin() {
        depth += 1
    }

    static func end() {
        if depth > 0 {
            depth -= 1
        }
    }

    static func whileApplying<T>(_ operation: () async throws -> T) async rethrows -> T {
        begin()
        defer { end() }
        return try await operation()
    }
}
