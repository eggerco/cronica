//
//  LibraryImportModels.swift
//  Cronica
//

import Foundation
import CronicaCore

enum LibraryImportSource: String, Sendable {
    case letterboxd
    case imdb
    case tmdbAccount
}

/// How an imported row should land in Cronica.
enum LibraryImportIntent: String, Sendable {
    /// On watchlist, not watched.
    case watchlist
    /// Marked watched (no rating required).
    case watched
    /// Watched + user rating when available.
    case rated
    /// Favorited (TMDB favorites).
    case favorite
}

struct LibraryImportRow: Sendable, Equatable {
    var title: String?
    var year: Int?
    var imdbID: String?
    var tmdbID: Int?
    var mediaHint: MediaType?
    var intent: LibraryImportIntent
    /// IMDb-style 1–10 (or Letterboxd mapped into this scale).
    var ratingOutOfTen: Double?
    /// Letterboxd native 0.5–5 stars.
    var letterboxdRating: Double?
}

struct LibraryImportSummary: Sendable, Equatable {
    var inserted = 0
    var updated = 0
    var skipped = 0
    var failed = 0
    var source: LibraryImportSource
    var unchanged = false

    var processed: Int { inserted + updated + skipped + failed }
}

enum LibraryImportResult: Sendable {
    case inserted
    case updated
    case skipped
}

enum LibraryImportError: LocalizedError, Sendable {
    case emptyFile
    case unrecognizedCSV
    case notConfigured
    case cancelled
    case invalidResponse
    case message(String)

    var errorDescription: String? {
        switch self {
        case .emptyFile:
            return String(localized: "The selected file is empty.")
        case .unrecognizedCSV:
            return String(localized: "This CSV doesn’t look like a Letterboxd or IMDb export Cronica understands.")
        case .notConfigured:
            return String(localized: "TMDB is not configured for this build.")
        case .cancelled:
            return String(localized: "Cancelled.")
        case .invalidResponse:
            return String(localized: "Unexpected response from TMDB.")
        case .message(let text):
            return text
        }
    }
}
