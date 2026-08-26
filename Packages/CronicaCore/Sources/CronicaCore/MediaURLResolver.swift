//
//  MediaURLResolver.swift
//  CronicaCore
//

import Foundation

public enum MediaURLResolver {
    /// How a shared URL maps to TMDb content.
    public enum Hint: Equatable, Sendable {
        case tmdb(TMDBURLParser.ContentReference)
        case imdb(id: String)
        case search(title: String, preferredType: MediaType?)
    }

    /// Parses movie/TV URLs from major review sites and Cronica/TMDb links.
    public static func parse(_ url: URL) -> Hint? {
        if let reference = TMDBURLParser.parse(url) {
            return .tmdb(reference)
        }

        guard let host = normalizedHost(url) else { return nil }

        switch host {
        case "imdb.com":
            return parseIMDb(url)
        case "letterboxd.com":
            return parseLetterboxd(url)
        case "rottentomatoes.com":
            return parseRottenTomatoes(url)
        case "trakt.tv":
            return parseTrakt(url)
        case "justwatch.com":
            return parseJustWatch(url)
        default:
            return nil
        }
    }

    private static func normalizedHost(_ url: URL) -> String? {
        guard var host = url.host()?.lowercased() else { return nil }
        if host.hasPrefix("www.") {
            host.removeFirst(4)
        }
        if host.hasPrefix("m.") {
            host.removeFirst(2)
        }
        return host
    }

    private static func parseIMDb(_ url: URL) -> Hint? {
        let parts = url.pathComponents.filter { $0 != "/" }
        guard parts.count >= 2,
              parts[0].lowercased() == "title",
              parts[1].lowercased().hasPrefix("tt"),
              parts[1].count >= 3
        else { return nil }

        let imdbID = parts[1].lowercased()
        return .imdb(id: imdbID)
    }

    private static func parseLetterboxd(_ url: URL) -> Hint? {
        let parts = url.pathComponents.filter { $0 != "/" }
        guard parts.count >= 2 else { return nil }

        switch parts[0].lowercased() {
        case "film":
            guard let title = titleFromSlug(parts[1]) else { return nil }
            return .search(title: title, preferredType: .movie)
        case "tv":
            guard let title = titleFromSlug(parts[1]) else { return nil }
            return .search(title: title, preferredType: .tvShow)
        default:
            return nil
        }
    }

    private static func parseRottenTomatoes(_ url: URL) -> Hint? {
        let parts = url.pathComponents.filter { $0 != "/" }
        guard parts.count >= 2 else { return nil }

        switch parts[0].lowercased() {
        case "m":
            guard let title = titleFromSlug(parts[1]) else { return nil }
            return .search(title: title, preferredType: .movie)
        case "tv":
            guard let title = titleFromSlug(parts[1]) else { return nil }
            return .search(title: title, preferredType: .tvShow)
        default:
            return nil
        }
    }

    private static func parseTrakt(_ url: URL) -> Hint? {
        let parts = url.pathComponents.filter { $0 != "/" }
        guard parts.count >= 2 else { return nil }

        switch parts[0].lowercased() {
        case "movies", "movie":
            guard let title = traktTitleFromSlug(parts[1]) else { return nil }
            return .search(title: title, preferredType: .movie)
        case "shows", "show":
            guard let title = titleFromSlug(parts[1]) else { return nil }
            return .search(title: title, preferredType: .tvShow)
        default:
            return nil
        }
    }

    private static func parseJustWatch(_ url: URL) -> Hint? {
        let parts = url.pathComponents.filter { $0 != "/" }
        guard parts.count >= 3 else { return nil }

        let preferredType: MediaType?
        switch parts[1].lowercased() {
        case "movie", "film":
            preferredType = .movie
        case "tv-show", "tv", "serie", "series", "show":
            preferredType = .tvShow
        default:
            return nil
        }

        guard let title = titleFromSlug(parts[2]) else { return nil }
        return .search(title: title, preferredType: preferredType)
    }

    static func traktTitleFromSlug(_ slug: String) -> String? {
        var cleaned = slug.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }

        if let yearSuffix = cleaned.range(of: #"-\d{4}$"#, options: .regularExpression) {
            cleaned.removeSubrange(yearSuffix)
        }

        return titleFromSlug(cleaned)
    }

    static func titleFromSlug(_ slug: String) -> String? {
        let trimmed = slug.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let decoded = trimmed.removingPercentEncoding ?? trimmed
        let title = decoded
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "+", with: " ")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")

        return title.isEmpty ? nil : title
    }
}
