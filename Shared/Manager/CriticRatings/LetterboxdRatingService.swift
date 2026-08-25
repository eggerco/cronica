//
//  LetterboxdRatingService.swift
//  Cronica
//

import Foundation

actor LetterboxdRatingService {
    static let shared = LetterboxdRatingService()

    private let session: URLSession

    private init(session: URLSession = .shared) {
        self.session = session
    }

    /// Reads the public average rating from a Letterboxd film page linked by IMDb ID.
    func fetchRating(imdbId: String) async throws -> String? {
        guard imdbId.hasPrefix("tt") else { return nil }
        guard let url = URL(string: "https://letterboxd.com/imdb/\(imdbId)/") else { return nil }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            return nil
        }
        guard let html = String(data: data, encoding: .utf8) else { return nil }

        if let match = html.firstMatch(of: /content="(\d+(?:\.\d+)?) out of 5"/) {
            return "\(match.1)/5"
        }
        if let match = html.firstMatch(of: /class="rating -green larger">(\d+(?:\.\d+)?)</) {
            return "\(match.1)/5"
        }
        return nil
    }
}
