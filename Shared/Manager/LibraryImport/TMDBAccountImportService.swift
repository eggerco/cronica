//
//  TMDBAccountImportService.swift
//  Cronica
//

import Foundation
import CronicaCore

enum TMDBAccountImportService {
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

        async let watchlistMovies = TMDBAccountAPIClient.shared.pagedAccountList(
            path: "watchlist/movies", sessionID: sessionID, accountID: accountID
        )
        async let watchlistTV = TMDBAccountAPIClient.shared.pagedAccountList(
            path: "watchlist/tv", sessionID: sessionID, accountID: accountID
        )
        async let ratedMovies = TMDBAccountAPIClient.shared.pagedAccountList(
            path: "rated/movies", sessionID: sessionID, accountID: accountID
        )
        async let ratedTV = TMDBAccountAPIClient.shared.pagedAccountList(
            path: "rated/tv", sessionID: sessionID, accountID: accountID
        )
        async let favoriteMovies = TMDBAccountAPIClient.shared.pagedAccountList(
            path: "favorite/movies", sessionID: sessionID, accountID: accountID
        )
        async let favoriteTV = TMDBAccountAPIClient.shared.pagedAccountList(
            path: "favorite/tv", sessionID: sessionID, accountID: accountID
        )

        let (wlMovies, wlTV, rMovies, rTV, fMovies, fTV) = try await (
            watchlistMovies, watchlistTV, ratedMovies, ratedTV, favoriteMovies, favoriteTV
        )

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

        return summary
    }
}
