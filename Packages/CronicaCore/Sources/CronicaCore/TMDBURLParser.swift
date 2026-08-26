//
//  TMDBURLParser.swift
//  CronicaCore
//

import Foundation

public enum TMDBURLParser {
    /// Parsed watchlist identity from a TMDB or Cronica details URL.
    public struct ContentReference: Equatable, Sendable {
        public let id: Int
        public let type: MediaType

        public var contentID: String {
            "\(id)@\(type.toInt)"
        }

        public init(id: Int, type: MediaType) {
            self.id = id
            self.type = type
        }
    }

    /// Parses TMDB movie/TV URLs and Cronica universal-link detail pages.
    public static func parse(_ url: URL) -> ContentReference? {
        if let cronicaReference = parseCronicaDetailsURL(url) {
            return cronicaReference
        }
        return parseTMDBURL(url)
    }

    private static func parseCronicaDetailsURL(_ url: URL) -> ContentReference? {
        guard url.host()?.lowercased() == "www.cronica.watch" else { return nil }
        let path = url.path()
        guard path == "/details" || path == "details" else { return nil }

        guard let contentID = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "id" })?
            .value,
              let reference = parseContentID(contentID)
        else { return nil }

        return reference
    }

    private static func parseTMDBURL(_ url: URL) -> ContentReference? {
        guard let host = url.host()?.lowercased(),
              host == "themoviedb.org" || host == "www.themoviedb.org"
        else { return nil }

        let parts = url.pathComponents.filter { $0 != "/" }
        guard parts.count >= 2, let id = parseNumericID(from: parts[1]) else { return nil }

        switch parts[0].lowercased() {
        case "movie":
            return ContentReference(id: id, type: .movie)
        case "tv":
            return ContentReference(id: id, type: .tvShow)
        default:
            return nil
        }
    }

    /// Parses Cronica content IDs such as `550@0` (movie) or `1399@1` (TV).
    public static func parseContentID(_ contentID: String) -> ContentReference? {
        let components = contentID.split(separator: "@", omittingEmptySubsequences: false)
        guard components.count == 2,
              let id = Int(components[0])
        else { return nil }

        switch components[1] {
        case "0":
            return ContentReference(id: id, type: .movie)
        case "1":
            return ContentReference(id: id, type: .tvShow)
        default:
            return nil
        }
    }

    private static func parseNumericID(from component: String) -> Int? {
        if let id = Int(component) {
            return id
        }
        let digits = component.prefix { $0.isNumber }
        guard !digits.isEmpty else { return nil }
        return Int(digits)
    }
}
