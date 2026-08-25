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
    static func importCSV(
        data: Data,
        source: LibraryImportSource,
        filename: String?,
        progress: (@MainActor (Progress) -> Void)? = nil
    ) async throws -> LibraryImportSummary {
        let rows: [LibraryImportRow]
        switch source {
        case .letterboxd:
            rows = try LetterboxdCSVParser.parse(data: data, filenameHint: filename)
        case .imdb:
            rows = try IMDbCSVParser.parse(data: data, filenameHint: filename)
        case .tmdbAccount:
            throw LibraryImportError.message("Use TMDB account import instead of CSV.")
        }

        return try await importRows(rows, source: source, progress: progress)
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
            if let letterboxd = row.letterboxdRating {
                item.userRating = LetterboxdCSVParser.cronicaRating(fromLetterboxd: letterboxd)
            } else if let ten = row.ratingOutOfTen {
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

    static func titlesRoughlyMatch(_ lhs: String, _ rhs: String) -> Bool {
        normalizeTitle(lhs) == normalizeTitle(rhs)
    }

    static func normalizeTitle(_ value: String) -> String {
        let folded = value.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let allowed = CharacterSet.alphanumerics.union(.whitespaces)
        return folded.unicodeScalars
            .filter { allowed.contains($0) }
            .map(String.init)
            .joined()
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Resolve

    private static func resolve(_ row: LibraryImportRow) async throws -> (Int, MediaType)? {
        if let tmdbID = row.tmdbID {
            let media = row.mediaHint ?? .movie
            return (tmdbID, media)
        }

        if let imdbID = row.imdbID {
            let found = try await NetworkService.shared.findByExternalID(imdbID, source: .imdbID)
            if let hint = row.mediaHint {
                if hint == .movie, let movie = found.movieResults?.first {
                    return (movie.id, .movie)
                }
                if hint == .tvShow, let show = found.tvResults?.first {
                    return (show.id, .tvShow)
                }
            }
            if let movie = found.movieResults?.first {
                return (movie.id, .movie)
            }
            if let show = found.tvResults?.first {
                return (show.id, .tvShow)
            }
            return nil
        }

        guard let title = row.title, !title.isEmpty else { return nil }
        return try await resolveByTitle(title, year: row.year, preferred: row.mediaHint ?? .movie)
    }

    private static func resolveByTitle(_ title: String, year: Int?, preferred: MediaType) async throws -> (Int, MediaType)? {
        let order: [MediaType] = preferred == .tvShow ? [.tvShow, .movie] : [.movie, .tvShow]
        for media in order {
            let results: [ItemContent]
            switch media {
            case .movie:
                results = try await NetworkService.shared.searchMovie(query: title, year: year)
            case .tvShow:
                results = try await NetworkService.shared.searchTV(query: title, firstAirYear: year)
            case .person:
                continue
            }
            if let match = bestTitleMatch(title: title, year: year, media: media, in: results) {
                return match
            }
        }
        return nil
    }

    private static func bestTitleMatch(
        title: String,
        year: Int?,
        media: MediaType,
        in results: [ItemContent]
    ) -> (Int, MediaType)? {
        guard !results.isEmpty else { return nil }
        let candidates = results.prefix(5)
        let exact = candidates.filter { item in
            let itemTitle = media == .movie ? (item.title ?? item.name ?? "") : (item.name ?? item.title ?? "")
            guard titlesRoughlyMatch(itemTitle, title) else { return false }
            guard let year else { return true }
            return itemYear(item, media: media) == year
        }
        // Require an unambiguous exact title (+ year when provided).
        if exact.count == 1, let only = exact.first {
            return (only.id, media)
        }
        if exact.isEmpty,
           let year,
           let first = candidates.first,
           itemYear(first, media: media) == year,
           titlesRoughlyMatch(
            media == .movie ? (first.title ?? first.name ?? "") : (first.name ?? first.title ?? ""),
            title
           ) {
            return (first.id, media)
        }
        return nil
    }

    private static func itemYear(_ item: ItemContent, media: MediaType) -> Int? {
        let dateString: String?
        switch media {
        case .movie: dateString = item.releaseDate
        case .tvShow: dateString = item.firstAirDate
        case .person: dateString = nil
        }
        guard let dateString, dateString.count >= 4 else { return nil }
        return Int(dateString.prefix(4))
    }

    @MainActor
    private static func markImported(source: LibraryImportSource) {
        let settings = SettingsStore.shared
        settings.userImportedTMDB = true
        let now = Date()
        switch source {
        case .letterboxd:
            settings.letterboxdLastImportDate = now
        case .imdb:
            settings.imdbLastImportDate = now
        case .tmdbAccount:
            settings.tmdbAccountLastImportDate = now
            settings.isUserConnectedWithTMDb = TMDBSessionStore.hasSession
        }
    }
}
