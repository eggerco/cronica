//
//  SimklImportMapper.swift
//  Cronica
//

import Foundation
import CronicaCore

enum SimklImportResult {
    case inserted
    case updated
    case skipped
}

enum SimklImportMapper {
    @MainActor
    static func importEntry(
        _ entry: SimklLibraryEntry,
        preferredMedia: MediaType,
        requireTMDB: Bool
    ) async throws -> SimklImportResult {
        guard let mediaObject = entry.mediaObject,
              let tmdbID = mediaObject.ids?.tmdb?.intValue else {
            return .skipped
        }

        let media: MediaType = {
            if preferredMedia == .movie || entry.movie != nil {
                return .movie
            }
            return .tvShow
        }()

        if requireTMDB, mediaObject.ids?.tmdb?.intValue == nil {
            return .skipped
        }

        let contentID = "\(tmdbID)@\(media.toInt)"
        let persistence = PersistenceController.shared
        let existed = persistence.isItemSaved(id: contentID)

        let content: ItemContent
        do {
            content = try await NetworkService.shared.fetchItem(id: tmdbID, type: media)
        } catch {
            // Still allow a minimal local row if TMDB lookup fails but we know the ID.
            if existed {
                applyStatus(entry, to: contentID, media: media)
                return .updated
            }
            throw error
        }

        if !existed {
            persistence.save(content)
        } else {
            persistence.update(item: content)
        }

        applyStatus(entry, to: content.itemContentID, media: media)
        SimklKnownItemsStore.insert(content.itemContentID)
        return existed ? .updated : .inserted
    }

    /// Maps SIMKL status / episode progress onto an existing Cronica watchlist item.
    @MainActor
    static func applyStatus(
        _ entry: SimklLibraryEntry,
        to contentID: String,
        media: MediaType,
        persistence: PersistenceController = .shared
    ) {
        guard let item = persistence.fetch(for: contentID) else { return }
        let status = entry.status ?? .plantowatch

        switch status {
        case .plantowatch:
            item.watched = false
            item.isWatching = false
            item.isArchive = false
        case .watching, .hold:
            item.watched = false
            item.isWatching = true
            item.isArchive = false
            applyEpisodes(entry, to: item)
        case .completed:
            item.watched = true
            item.isWatching = false
            item.isArchive = false
            if media == .tvShow {
                applyEpisodes(entry, to: item)
            }
        case .dropped:
            item.watched = false
            item.isWatching = false
            item.isArchive = true
        }

        if item.watched {
            if let parsed = parseSimklDate(entry.lastWatchedAt) {
                item.watchedDate = parsed
            } else if item.watchedDate == nil {
                // Keep nil for historical imports without a date rather than inventing "now".
            }
        } else {
            item.watchedDate = nil
        }

        if let rating = entry.userRating {
            // SIMKL uses 1–10; Cronica stores 0–5 stars.
            item.userRating = Int64(max(0, min(5, (rating + 1) / 2)))
        }

        item.lastValuesUpdated = Date()
        persistence.save()
    }

    @MainActor
    private static func applyEpisodes(_ entry: SimklLibraryEntry, to item: WatchlistItem) {
        guard let seasons = entry.seasons, !seasons.isEmpty else { return }
        var watched = item.watchedEpisodes ?? ""
        for season in seasons {
            guard let seasonNumber = season.number else { continue }
            for episode in season.episodes ?? [] {
                guard episode.isWatched, let episodeNumber = episode.number else { continue }
                let token = episodeToken(episode: episodeNumber, season: seasonNumber)
                if !watched.contains(token) {
                    watched.append(token)
                }
            }
        }
        item.watchedEpisodes = watched
        if !watched.isEmpty {
            item.isWatching = item.isWatching || !(entry.status == .completed)
        }
    }

    // MARK: - Test helpers

    static func contentID(tmdbID: Int, media: MediaType) -> String {
        "\(tmdbID)@\(media.toInt)"
    }

    static func cronicaRating(fromSimkl rating: Int) -> Int64 {
        Int64(max(0, min(5, (rating + 1) / 2)))
    }

    /// Cronica 0–5 stars → SIMKL 1–10 (0 clears).
    static func simklRating(fromCronica rating: Int) -> Int {
        max(0, min(10, rating * 2))
    }

    static func shouldSkipAnimeWithoutTMDB(_ entry: SimklLibraryEntry) -> Bool {
        entry.mediaObject?.ids?.tmdb?.intValue == nil
    }


    static func parseSimklDate(_ value: String?) -> Date? {
        guard let value, !value.isEmpty else { return nil }
        let isoFractional = ISO8601DateFormatter()
        isoFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFractional.date(from: value) { return date }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        if let date = iso.date(from: value) { return date }
        let day = DateFormatter()
        day.calendar = Calendar(identifier: .gregorian)
        day.locale = Locale(identifier: "en_US_POSIX")
        day.timeZone = TimeZone(secondsFromGMT: 0)
        day.dateFormat = "yyyy-MM-dd"
        return day.date(from: value)
    }

    static func episodeToken(episode: Int, season: Int) -> String {
        "-\(episode)@\(season)"
    }

    static func watchedEpisodeTokens(from entry: SimklLibraryEntry) -> [String] {
        guard let seasons = entry.seasons else { return [] }
        var tokens: [String] = []
        for season in seasons {
            guard let seasonNumber = season.number else { continue }
            for episode in season.episodes ?? [] {
                guard episode.isWatched, let episodeNumber = episode.number else { continue }
                tokens.append(episodeToken(episode: episodeNumber, season: seasonNumber))
            }
        }
        return tokens
    }
}
