//
//  LibraryImportModels.swift
//  Cronica
//

import Foundation
import CronicaCore

enum LibraryImportSource: String, Sendable {
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
    var tmdbID: Int?
    var mediaHint: MediaType?
    var intent: LibraryImportIntent
    /// TMDB-style 1–10 rating.
    var ratingOutOfTen: Double?
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
    case notConfigured
    case cancelled
    case invalidResponse
    case message(String)

    var errorDescription: String? {
        switch self {
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
