//
//  LibraryImportService.swift
//  Cronica
//

import Foundation
import CronicaCore

enum LibraryImportService {
    struct Progress: Sendable {
        var phase: String
        var processed: Int
        var total: Int
    }

    @MainActor
    static func importRows(
        _ rows: [LibraryImportRow],
        source: LibraryImportSource,
        progress: (@MainActor (Progress) -> Void)? = nil
    ) async throws -> LibraryImportSummary {
        var summary = LibraryImportSummary(source: source)
        let total = rows.count
        progress?(Progress(phase: String(localized: "Importing…"), processed: 0, total: total))

        for (index, row) in rows.enumerated() {
            try Task.checkCancellation()
            do {
                let result = try await importRow(row)
                switch result {
                case .inserted: summary.inserted += 1
                case .updated: summary.updated += 1
                case .skipped: summary.skipped += 1
                }
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                summary.failed += 1
            }
            progress?(Progress(phase: String(localized: "Importing…"), processed: index + 1, total: total))
            // Soft pacing against TMDB rate limits on large libraries.
            if index % 8 == 7 {
                try await Task.sleep(nanoseconds: 120_000_000)
            }
        }

        markImported(source: source)
        return summary
    }

    @MainActor
    static func importRow(_ row: LibraryImportRow) async throws -> LibraryImportResult {
        guard let resolved = try await resolve(row) else {
            return .skipped
        }
        let (tmdbID, media) = resolved
        let contentID = "\(tmdbID)@\(media.toInt)"
        let persistence = PersistenceController.shared
        let existed = persistence.isItemSaved(id: contentID)

        let content: ItemContent
        do {
            content = try await NetworkService.shared.fetchItem(id: tmdbID, type: media)
        } catch {
            if existed {
                applyIntent(row, to: contentID)
                return .updated
            }
            throw error
        }

        if !existed {
            persistence.save(content)
        } else {
            persistence.update(item: content)
        }
        applyIntent(row, to: content.itemContentID)
        return existed ? .updated : .inserted
    }

    @MainActor
    static func applyIntent(_ row: LibraryImportRow, to contentID: String) {
        let persistence = PersistenceController.shared
        guard let item = persistence.fetch(for: contentID) else { return }

        switch row.intent {
        case .watchlist:
            // Keep existing watched/favorite state if already present.
            if item.watched == false && item.isWatching == false {
                item.isArchive = false
            }
        case .watched:
            item.watched = true
            item.isWatching = false
            item.isArchive = false
        case .rated:
            item.watched = true
            item.isWatching = false
            item.isArchive = false
            if let ten = row.ratingOutOfTen {
                item.userRating = cronicaRating(fromTenPoint: ten)
            }
        case .favorite:
            item.favorite = true
        }

        item.lastValuesUpdated = Date()
        persistence.save()
    }

    static func cronicaRating(fromTenPoint rating: Double) -> Int64 {
        let clamped = max(0, min(10, rating))
        // Match SIMKL-style mapping: 1–10 → 0–5 via (n + 1) / 2.
        return Int64(max(0, min(5, Int((clamped + 1) / 2))))
    }

    /// Cronica 0–5 stars → TMDB 0–10 (half-star friendly even integers).
    static func tenPointRating(fromCronica rating: Int) -> Double {
        Double(max(0, min(10, rating * 2)))
    }

    // MARK: - Resolve

    private static func resolve(_ row: LibraryImportRow) async throws -> (Int, MediaType)? {
        guard let tmdbID = row.tmdbID else { return nil }
        let media = row.mediaHint ?? .movie
        return (tmdbID, media)
    }

    @MainActor
    private static func markImported(source: LibraryImportSource) {
        let settings = SettingsStore.shared
        settings.userImportedTMDB = true
        let now = Date()
        switch source {
        case .tmdbAccount:
            settings.tmdbAccountLastImportDate = now
            settings.isUserConnectedWithTMDb = TMDBSessionStore.hasSession
        }
    }
}
