//
//  TMDBSyncService.swift
//  Cronica
//

import Foundation
import CronicaCore

/// Pulls TMDB account lists → Cronica.
///
/// TMDB has no SIMKL-style activities feed, so every sync re-downloads watchlist,
/// ratings, and favorites. Manual Sync Now always runs; foreground checks are throttled.
@MainActor
enum TMDBSyncService {
    /// Match SIMKL’s ~20 minute foreground throttle.
    nonisolated static let foregroundThrottleInterval: TimeInterval = 20 * 60

    private static var isApplyingRemote = false

    static var isApplyingRemoteChanges: Bool { isApplyingRemote }

    struct Progress: Equatable {
        var phase: String
        var processed: Int
        var total: Int
    }

    /// Full account-list pull (watchlist, ratings, favorites).
    static func syncNow(
        progress: (@MainActor (LibraryImportService.Progress) -> Void)? = nil
    ) async throws -> LibraryImportSummary {
        guard TMDBSessionStore.hasSession else {
            throw LibraryImportError.message("Connect a TMDB account first.")
        }
        isApplyingRemote = true
        defer { isApplyingRemote = false }

        let summary = try await TMDBAccountImportService.importLibrary(progress: progress)
        SettingsStore.shared.markTMDBSyncChecked()
        return summary
    }

    /// Foreground / wake pull. Skipped when throttled or no session.
    static func syncIfNeededOnForeground() async {
        guard TMDBSessionStore.hasSession else { return }
        let settings = SettingsStore.shared
        guard settings.tmdbAccountLastImportDate != nil else { return }
        if shouldSkipForegroundCheck(
            lastCheck: settings.tmdbLastSyncCheckTimestamp,
            now: Date().timeIntervalSince1970
        ) {
            return
        }
        do {
            _ = try await syncNow()
            if settings.tmdbPushEnabled {
                await TMDBPushService.shared.flush()
            }
        } catch is CancellationError {
            // ignored
        } catch {
            AppLogger.network.error("TMDB foreground sync failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    nonisolated static func shouldSkipForegroundCheck(lastCheck: TimeInterval, now: TimeInterval) -> Bool {
        guard lastCheck > 0 else { return false }
        return (now - lastCheck) < foregroundThrottleInterval
    }
}
