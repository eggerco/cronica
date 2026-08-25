//
//  SimklAccountService.swift
//  Cronica
//

import Foundation
import CronicaCore

/// User-triggered SIMKL account helpers (settings cache, stats, playbacks).
@MainActor
enum SimklAccountService {
    /// Caches `account.id` from `/users/settings`. Call after connect or when stats are needed.
    static func ensureAccountID() async throws -> Int {
        let settings = SettingsStore.shared
        if settings.simklAccountID > 0 {
            return settings.simklAccountID
        }
        let profile = try await SimklAPIClient.shared.fetchUserSettings()
        guard let id = profile.account?.id, id > 0 else {
            throw SimklError.message(String(localized: "Could not load your SIMKL account id."))
        }
        settings.simklAccountID = id
        settings.simklAccountName = profile.user?.name ?? ""
        return id
    }

    /// Expensive — only call from an explicit user action (Load Stats button).
    static func loadStats() async throws -> SimklUserStats {
        let id = try await ensureAccountID()
        let stats = try await SimklAPIClient.shared.fetchUserStats(userID: id)
        SettingsStore.shared.simklLastStatsFetchDate = Date()
        return stats
    }

    /// Paused playbacks from other devices. Gate with activities in callers when doing background work.
    static func loadPlaybacks() async throws -> [SimklPlaybackEntry] {
        let response = try await SimklAPIClient.shared.fetchPlayback()
        let movies = response.movies ?? []
        let episodes = response.episodes ?? []
        return movies + episodes
    }
}
