//
//  IMDbCSVParser.swift
//  Cronica
//

import Foundation
import CronicaCore

enum IMDbCSVParser {
    /// Parses IMDb desktop CSV exports (ratings, watchlist, or custom lists).
    static func parse(data: Data, filenameHint: String? = nil) throws -> [LibraryImportRow] {
        let table = try CSVTable.parse(data)
        return try parse(table: table, filenameHint: filenameHint)
    }

    static func parse(table: CSVTable.Table, filenameHint: String? = nil) throws -> [LibraryImportRow] {
        let headers = Set(table.headers)
        let hasConst = headers.contains("const")
        guard hasConst else { throw LibraryImportError.unrecognizedCSV }

        let hasYourRating = headers.contains("your rating") || headers.contains("you rated")
        let defaultIntent: LibraryImportIntent = {
            let name = (filenameHint ?? "").lowercased()
            // Filename wins — IMDb watchlist CSVs still include an empty "Your Rating" column.
            if name.contains("watchlist") { return .watchlist }
            if name.contains("rating") { return .rated }
            if hasYourRating { return .rated }
            return .watchlist
        }()

        return table.rows.compactMap { row in
            guard let constRaw = CSVTable.value(row, keys: "Const", "const"),
                  let imdbID = normalizeIMDbID(constRaw) else {
                return nil
            }

            let title = CSVTable.value(row, keys: "Title", "Original Title")
            let year = Int(CSVTable.value(row, keys: "Year") ?? "")
            let titleType = CSVTable.value(row, keys: "Title Type", "Title type")
            let mediaHint = mediaType(fromTitleType: titleType)

            let ratingRaw = CSVTable.value(row, keys: "Your Rating", "You rated")
            let rating = Double(ratingRaw ?? "")
            let intent: LibraryImportIntent = {
                if let rating, rating > 0 { return .rated }
                return defaultIntent
            }()

            // Skip episode-level rows — Cronica tracks shows, not individual episodes.
            if mediaHint == nil, let titleType, titleType.localizedCaseInsensitiveContains("episode") {
                return nil
            }

            return LibraryImportRow(
                title: title,
                year: year,
                imdbID: imdbID,
                tmdbID: nil,
                mediaHint: mediaHint,
                intent: intent,
                ratingOutOfTen: rating,
                letterboxdRating: nil
            )
        }
    }

    static func normalizeIMDbID(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        if trimmed.lowercased().hasPrefix("tt") {
            return trimmed.lowercased()
        }
        if trimmed.allSatisfy(\.isNumber) {
            return "tt" + trimmed
        }
        // URL form: https://www.imdb.com/title/tt0111161/
        if let range = trimmed.range(of: #"tt\d+"#, options: .regularExpression) {
            return String(trimmed[range]).lowercased()
        }
        return nil
    }

    static func mediaType(fromTitleType raw: String?) -> MediaType? {
        guard let raw else { return nil }
        let value = raw.lowercased()
        if value.contains("episode") { return nil }
        if value.contains("tv series")
            || value.contains("tv mini")
            || value.contains("tv mini-series")
            || value.contains("tv mini series") {
            return .tvShow
        }
        if value.contains("movie")
            || value.contains("short")
            || value.contains("video")
            || value.contains("tv special")
            || value.contains("tv movie")
            || value.contains("tv short") {
            return .movie
        }
        return nil
    }
}
