//
//  SimklImportService.swift
//  Cronica
//

import Foundation
import CronicaCore

@MainActor
enum SimklImportService {
    struct Progress: Equatable {
        var phase: String
        var processed: Int
        var total: Int
    }

    static func importLibrary(
        progress: (@MainActor (Progress) -> Void)? = nil
    ) async throws -> SimklImportSummary {
        guard SimklTokenStore.hasToken else { throw SimklError.notAuthenticated }

        var summary = SimklImportSummary()
        let client = SimklAPIClient.shared

        progress?(Progress(phase: String(localized: "Importing movies…"), processed: 0, total: 0))
        let movies = try await client.fetchAllItems(type: .movies)
        try await applyEntries(
            movies.movies ?? [],
            media: .movie,
            summary: &summary,
            progress: progress,
            phase: String(localized: "Importing movies…")
        )

        progress?(Progress(phase: String(localized: "Importing TV shows…"), processed: 0, total: 0))
        let shows = try await client.fetchAllItems(
            type: .shows,
            extended: "full",
            includeAllEpisodes: true,
            episodeWatchedAt: true
        )
        try await applyEntries(
            shows.shows ?? [],
            media: .tvShow,
            summary: &summary,
            progress: progress,
            phase: String(localized: "Importing TV shows…")
        )

        progress?(Progress(phase: String(localized: "Importing anime…"), processed: 0, total: 0))
        let anime = try await client.fetchAllItems(type: .anime)
        try await applyEntries(
            anime.anime ?? [],
            media: .tvShow,
            summary: &summary,
            progress: progress,
            phase: String(localized: "Importing anime…"),
            requireTMDB: true
        )

        SettingsStore.shared.simklLastImportDate = Date()
        SettingsStore.shared.isSimklConnected = true
        SettingsStore.shared.userImportedTMDB = true
        return summary
    }

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
                AppLogger.network.error("SIMKL import item failed: \(error.localizedDescription, privacy: .public)")
            }
        }
        progress?(Progress(phase: phase, processed: total, total: total))
    }
}
