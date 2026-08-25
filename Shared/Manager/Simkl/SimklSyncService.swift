//
//  SimklSyncService.swift
//  Cronica
//

import Foundation
import CronicaCore

/// Pulls SIMKL → Cronica using the official two-phase model (full, then activities + date_from).
@MainActor
enum SimklSyncService {
    private static var isApplyingRemote = false

    static var isApplyingRemoteChanges: Bool { isApplyingRemote }

    struct Progress: Equatable {
        var phase: String
        var processed: Int
        var total: Int
    }

    /// Full library pull (Phase 1). Also seeds `activities.all` for later incremental sync.
    static func fullImport(
        progress: (@MainActor (Progress) -> Void)? = nil
    ) async throws -> SimklImportSummary {
        guard SimklTokenStore.hasToken else { throw SimklError.notAuthenticated }
        isApplyingRemote = true
        defer { isApplyingRemote = false }

        var summary = SimklImportSummary()
        let client = SimklAPIClient.shared

        progress?(Progress(phase: String(localized: "Importing movies…"), processed: 0, total: 0))
        let movies = try await client.fetchAllItems(type: .movies)
        try await applyEntries(movies.movies ?? [], media: .movie, summary: &summary, progress: progress, phase: String(localized: "Importing movies…"))

        progress?(Progress(phase: String(localized: "Importing TV shows…"), processed: 0, total: 0))
        let shows = try await client.fetchAllItems(
            type: .shows,
            extended: "full",
            includeAllEpisodes: true,
            episodeWatchedAt: true
        )
        try await applyEntries(shows.shows ?? [], media: .tvShow, summary: &summary, progress: progress, phase: String(localized: "Importing TV shows…"))

        progress?(Progress(phase: String(localized: "Importing anime…"), processed: 0, total: 0))
        let anime = try await client.fetchAllItems(type: .anime)
        try await applyEntries(anime.anime ?? [], media: .tvShow, summary: &summary, progress: progress, phase: String(localized: "Importing anime…"), requireTMDB: true)

        try await persistActivitiesSnapshot()
        finishLocalFlags()
        return summary
    }

    /// Phase 2 incremental pull. Call on foreground / manual Sync — never on a blind timer.
    static func incrementalSync(
        progress: (@MainActor (Progress) -> Void)? = nil
    ) async throws -> SimklImportSummary {
        guard SimklTokenStore.hasToken else { throw SimklError.notAuthenticated }

        let settings = SettingsStore.shared
        guard !settings.simklActivitiesAll.isEmpty else {
            return try await fullImport(progress: progress)
        }

        progress?(Progress(phase: String(localized: "Checking SIMKL…"), processed: 0, total: 0))
        let activities = try await SimklAPIClient.shared.fetchActivities()
        guard let remoteAll = activities.all, !remoteAll.isEmpty else {
            throw SimklError.invalidResponse
        }

        if remoteAll == settings.simklActivitiesAll {
            var summary = SimklImportSummary()
            summary.unchanged = true
            settings.simklLastImportDate = Date()
            return summary
        }

        isApplyingRemote = true
        defer { isApplyingRemote = false }

        var summary = SimklImportSummary()
        progress?(Progress(phase: String(localized: "Syncing changes…"), processed: 0, total: 0))
        let delta = try await SimklAPIClient.shared.fetchAllItems(
            dateFrom: settings.simklActivitiesAll,
            extended: "full",
            includeAllEpisodes: true,
            episodeWatchedAt: true
        )

        try await applyEntries(delta.movies ?? [], media: .movie, summary: &summary, progress: progress, phase: String(localized: "Syncing movies…"))
        try await applyEntries(delta.shows ?? [], media: .tvShow, summary: &summary, progress: progress, phase: String(localized: "Syncing TV shows…"))
        try await applyEntries(delta.anime ?? [], media: .tvShow, summary: &summary, progress: progress, phase: String(localized: "Syncing anime…"), requireTMDB: true)

        if hasRemovals(activities: activities, previous: settings) {
            // Policy: never auto-delete Cronica items when they disappear on SIMKL.
            summary.removedOnSimkl = try await reconcileRemovalsWithoutDeleting(progress: progress)
        }

        settings.simklActivitiesAll = remoteAll
        settings.simklRemovedMovies = activities.movies?.removedFromList ?? ""
        settings.simklRemovedShows = activities.tvShows?.removedFromList ?? ""
        settings.simklRemovedAnime = activities.anime?.removedFromList ?? ""
        finishLocalFlags()
        return summary
    }

    /// Foreground-safe sync: incremental if seeded, otherwise no-op until user imports.
    static func syncIfNeededOnForeground() async {
        guard Key.isSimklConfigured, SimklTokenStore.hasToken else { return }
        guard !SettingsStore.shared.simklActivitiesAll.isEmpty else { return }
        do {
            _ = try await incrementalSync()
            if SettingsStore.shared.simklPushEnabled {
                await SimklPushService.shared.flush()
            }
        } catch {
            AppLogger.network.error("SIMKL foreground sync failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Private

    private static func applyEntries(
        _ entries: [SimklLibraryEntry],
        media: MediaType,
        summary: inout SimklImportSummary,
        progress: (@MainActor (Progress) -> Void)?,
        phase: String,
        requireTMDB: Bool = false
    ) async throws {
        let total = entries.count
        for (index, entry) in entries.enumerated() {
            try Task.checkCancellation()
            progress?(Progress(phase: phase, processed: index, total: total))
            do {
                let result = try await SimklImportMapper.importEntry(entry, preferredMedia: media, requireTMDB: requireTMDB)
                switch result {
                case .inserted: summary.inserted += 1
                case .updated: summary.updated += 1
                case .skipped: summary.skipped += 1
                }
            } catch {
                summary.failed += 1
                AppLogger.network.error("SIMKL sync item failed: \(error.localizedDescription, privacy: .public)")
            }
        }
        progress?(Progress(phase: phase, processed: total, total: total))
    }

    private static func persistActivitiesSnapshot() async throws {
        let activities = try await SimklAPIClient.shared.fetchActivities()
        let settings = SettingsStore.shared
        settings.simklActivitiesAll = activities.all ?? ""
        settings.simklRemovedMovies = activities.movies?.removedFromList ?? ""
        settings.simklRemovedShows = activities.tvShows?.removedFromList ?? ""
        settings.simklRemovedAnime = activities.anime?.removedFromList ?? ""
    }

    private static func finishLocalFlags() {
        SettingsStore.shared.simklLastImportDate = Date()
        SettingsStore.shared.isSimklConnected = true
        SettingsStore.shared.userImportedTMDB = true
    }

    private static func hasRemovals(activities: SimklActivitiesResponse, previous: SettingsStore) -> Bool {
        (activities.movies?.removedFromList ?? "") != previous.simklRemovedMovies
            || (activities.tvShows?.removedFromList ?? "") != previous.simklRemovedShows
            || (activities.anime?.removedFromList ?? "") != previous.simklRemovedAnime
    }

    /// Counts known SIMKL titles missing from the remote ids_only snapshot. Does not delete local rows.
    private static func reconcileRemovalsWithoutDeleting(
        progress: (@MainActor (Progress) -> Void)?
    ) async throws -> Int {
        progress?(Progress(phase: String(localized: "Checking removals…"), processed: 0, total: 0))
        let remote = try await SimklAPIClient.shared.fetchAllItems(extended: "ids_only")
        var remoteIDs = Set<String>()
        for entry in (remote.movies ?? []) {
            if let tmdb = entry.mediaObject?.ids?.tmdb?.intValue {
                remoteIDs.insert(SimklImportMapper.contentID(tmdbID: tmdb, media: .movie))
            }
        }
        for entry in (remote.shows ?? []) + (remote.anime ?? []) {
            if let tmdb = entry.mediaObject?.ids?.tmdb?.intValue {
                remoteIDs.insert(SimklImportMapper.contentID(tmdbID: tmdb, media: .tvShow))
            }
        }

        let known = SimklKnownItemsStore.all()
        let missing = known.subtracting(remoteIDs)
        SimklKnownItemsStore.replace(with: known.intersection(remoteIDs))
        return missing.count
    }
}
