//
//  AppWebsite.swift
//  Cronica
//

import Foundation

enum AppWebsite {
    static let baseURL = URL(string: "https://www.cronica.watch")!

    static var privacyPolicy: URL {
        baseURL.appending(path: "privacy")
    }

    /// Shareable details page. Pass raw `title` / poster path — `URLQueryItem` encodes once.
    static func detailsURL(contentID: String, posterPath: String?, title: String) -> URL? {
        var components = URLComponents(url: baseURL.appending(path: "details"), resolvingAgainstBaseURL: false)
        var items = [
            URLQueryItem(name: "id", value: contentID),
            URLQueryItem(name: "title", value: title.trimmingCharacters(in: .whitespacesAndNewlines))
        ]
        if let poster = normalizedPosterPath(posterPath) {
            items.append(URLQueryItem(name: "img", value: poster))
        }
        components?.queryItems = items
        return components?.url
    }

    /// TMDb poster paths as stored on items (`/abc.jpg`) → query value without a leading slash.
    private static func normalizedPosterPath(_ path: String?) -> String? {
        guard let path else { return nil }
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return trimmed.hasPrefix("/") ? String(trimmed.dropFirst()) : trimmed
    }
}
