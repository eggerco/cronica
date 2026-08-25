//
//  LetterboxdCSVParser.swift
//  Cronica
//

import Foundation
import CronicaCore

enum LetterboxdCSVParser {
    /// Parses Letterboxd export CSVs (`watchlist.csv`, `watched.csv`, `ratings.csv`, `diary.csv`).
    /// Letterboxd exports do **not** include TMDB/IMDb IDs — rows resolve later by title + year.
    static func parse(data: Data, filenameHint: String? = nil) throws -> [LibraryImportRow] {
        let table = try CSVTable.parse(data)
        return try parse(table: table, filenameHint: filenameHint)
    }

    static func parse(table: CSVTable.Table, filenameHint: String? = nil) throws -> [LibraryImportRow] {
        let headers = Set(table.headers)
        let hasName = headers.contains("name")
        let hasLetterboxdURI = headers.contains("letterboxd uri")
        guard hasName, hasLetterboxdURI || headers.contains("year") else {
            throw LibraryImportError.unrecognizedCSV
        }
        // Reject IMDb exports that also have Name-like fields accidentally.
        if headers.contains("const") {
            throw LibraryImportError.unrecognizedCSV
        }

        let defaultIntent = intent(fromFilename: filenameHint, headers: headers)

        var rows: [LibraryImportRow] = []
        for row in table.rows {
            guard let title = CSVTable.value(row, keys: "Name"), !title.isEmpty else { continue }
            let year = Int(CSVTable.value(row, keys: "Year") ?? "")
            let ratingRaw = CSVTable.value(row, keys: "Rating")
            let letterboxdRating = Double(ratingRaw ?? "")

            let intent: LibraryImportIntent = {
                if let letterboxdRating, letterboxdRating > 0 { return .rated }
                return defaultIntent
            }()

            rows.append(
                LibraryImportRow(
                    title: title,
                    year: year,
                    imdbID: nil,
                    tmdbID: nil,
                    mediaHint: .movie,
                    intent: intent,
                    ratingOutOfTen: letterboxdRating.map { $0 * 2 },
                    letterboxdRating: letterboxdRating
                )
            )
        }
        return rows
    }

    static func intent(fromFilename filename: String?, headers: Set<String>) -> LibraryImportIntent {
        let name = (filename ?? "").lowercased()
        if name.contains("watchlist") { return .watchlist }
        if name.contains("rating") { return .rated }
        if name.contains("watched") || name.contains("diary") { return .watched }
        if headers.contains("rating") { return .rated }
        return .watchlist
    }

    /// Cronica stores 0–5 integer stars; Letterboxd uses half-stars (rounded).
    static func cronicaRating(fromLetterboxd rating: Double) -> Int64 {
        Int64(max(0, min(5, rating.rounded())))
    }
}
