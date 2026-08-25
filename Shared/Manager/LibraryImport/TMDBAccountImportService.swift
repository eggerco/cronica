//
//  TMDBAccountImportService.swift
//  Cronica
//

import Foundation
import CronicaCore

enum TMDBAccountImportService {
    private static let listPaths = [
        "watchlist/movies",
        "watchlist/tv",
        "rated/movies",
        "rated/tv",
        "favorite/movies",
        "favorite/tv"
    ]

    /// Foreground light probe: page-1 conditional GETs for every account list.
    /// Returns `true` only when every list page is Not Modified and a prior fingerprint exists.
    @MainActor
    static func probeListsUnchanged() async throws -> Bool {
        guard TMDBAccountListCache.loadFingerprint() != nil else { return false }
        guard let sessionID = TMDBSessionStore.loadSessionID() else { return false }
        var accountID = TMDBSessionStore.loadAccountID()
        if accountID == 0 {
            let details = try await TMDBAccountAPIClient.shared.accountDetails(sessionID: sessionID)
            accountID = details.id
            TMDBSessionStore.saveAccountID(accountID)
        }
        for path in listPaths {
            let unchanged = try await TMDBAccountAPIClient.shared.isAccountListPageUnchanged(
                path: path,
                sessionID: sessionID,
                accountID: accountID,
                page: 1
            )
            if !unchanged { return false }
        }
        return true
    }

    @MainActor
    static func importLibrary(
        progress: (@MainActor (LibraryImportService.Progress) -> Void)? = nil
    ) async throws -> LibraryImportSummary {
        guard let sessionID = TMDBSessionStore.loadSessionID() else {
            throw LibraryImportError.message("Connect a TMDB account first.")
        }
        var accountID = TMDBSessionStore.loadAccountID()
        if accountID == 0 {
            let details = try await TMDBAccountAPIClient.shared.accountDetails(sessionID: sessionID)
            accountID = details.id
            TMDBSessionStore.saveAccountID(accountID)
            SettingsStore.shared.tmdbAccountName = details.username ?? details.name ?? ""
            SettingsStore.shared.isUserConnectedWithTMDb = true
        }

        progress?(LibraryImportService.Progress(phase: String(localized: "Fetching TMDB lists…"), processed: 0, total: 0))

        // Sequential list pulls with per-page pacing (safer for rate limits than 6-way fan-out).
        let wlMovies = try await TMDBAccountAPIClient.shared.pagedAccountList(
            path: "watchlist/movies", sessionID: sessionID, accountID: accountID
        )
        let wlTV = try await TMDBAccountAPIClient.shared.pagedAccountList(
            path: "watchlist/tv", sessionID: sessionID, accountID: accountID
        )
        let rMovies = try await TMDBAccountAPIClient.shared.pagedAccountList(
            path: "rated/movies", sessionID: sessionID, accountID: accountID
        )
        let rTV = try await TMDBAccountAPIClient.shared.pagedAccountList(
            path: "rated/tv", sessionID: sessionID, accountID: accountID
        )
        let fMovies = try await TMDBAccountAPIClient.shared.pagedAccountList(
            path: "favorite/movies", sessionID: sessionID, accountID: accountID
        )
        let fTV = try await TMDBAccountAPIClient.shared.pagedAccountList(
            path: "favorite/tv", sessionID: sessionID, accountID: accountID
        )

        let fingerprint = TMDBAccountListCache.fingerprint(
            watchlistMovies: wlMovies,
            watchlistTV: wlTV,
            ratedMovies: rMovies,
            ratedTV: rTV,
            favoriteMovies: fMovies,
            favoriteTV: fTV
        )
        if fingerprint == TMDBAccountListCache.loadFingerprint() {
            SettingsStore.shared.tmdbAccountLastImportDate = Date()
            SettingsStore.shared.isUserConnectedWithTMDb = true
            SettingsStore.shared.userImportedTMDB = true
            return LibraryImportSummary(source: .tmdbAccount, unchanged: true)
        }

        var rows: [LibraryImportRow] = []
        rows.append(contentsOf: wlMovies.map {
            LibraryImportRow(title: $0.title, tmdbID: $0.id, mediaHint: .movie, intent: .watchlist, ratingOutOfTen: nil)
        })
        rows.append(contentsOf: wlTV.map {
            LibraryImportRow(title: $0.name, tmdbID: $0.id, mediaHint: .tvShow, intent: .watchlist, ratingOutOfTen: nil)
        })
        rows.append(contentsOf: rMovies.map {
            LibraryImportRow(title: $0.title, tmdbID: $0.id, mediaHint: .movie, intent: .rated, ratingOutOfTen: $0.rating)
        })
        rows.append(contentsOf: rTV.map {
            LibraryImportRow(title: $0.name, tmdbID: $0.id, mediaHint: .tvShow, intent: .rated, ratingOutOfTen: $0.rating)
        })
        rows.append(contentsOf: fMovies.map {
            LibraryImportRow(title: $0.title, tmdbID: $0.id, mediaHint: .movie, intent: .favorite, ratingOutOfTen: nil)
        })
        rows.append(contentsOf: fTV.map {
            LibraryImportRow(title: $0.name, tmdbID: $0.id, mediaHint: .tvShow, intent: .favorite, ratingOutOfTen: nil)
        })

        // Deduplicate by content ID; prefer rated over watchlist. Favorites applied after.
        let priority: [LibraryImportIntent: Int] = [.rated: 3, .watched: 2, .favorite: 2, .watchlist: 1]
        var best: [String: LibraryImportRow] = [:]
        for row in rows where row.intent != .favorite {
            guard let id = row.tmdbID, let media = row.mediaHint else { continue }
            let key = "\(id)@\(media.toInt)"
            if let existing = best[key], (priority[existing.intent] ?? 0) >= (priority[row.intent] ?? 0) {
                continue
            }
            best[key] = row
        }

        let favoriteKeys = Set(
            fMovies.map { "\($0.id)@\(MediaType.movie.toInt)" }
                + fTV.map { "\($0.id)@\(MediaType.tvShow.toInt)" }
        )

        // Ensure favorite-only titles still get imported.
        for row in rows where row.intent == .favorite {
            guard let id = row.tmdbID, let media = row.mediaHint else { continue }
            let key = "\(id)@\(media.toInt)"
            if best[key] == nil {
                best[key] = LibraryImportRow(
                    title: row.title,
                    tmdbID: id,
                    mediaHint: media,
                    intent: .watchlist,
                    ratingOutOfTen: nil
                )
            }
        }

        let summary = try await LibraryImportService.importRows(
            Array(best.values),
            source: .tmdbAccount,
            progress: progress
        )

        for key in favoriteKeys {
            if let item = PersistenceController.shared.fetch(for: key) {
                item.favorite = true
                item.lastValuesUpdated = Date()
            }
        }
        PersistenceController.shared.save()

        // Only seal fingerprint when apply completed without item failures,
        // so a partial failure retries those rows on the next sync.
        if summary.failed == 0 {
            TMDBAccountListCache.saveFingerprint(fingerprint)
        }

        return summary
    }
}
