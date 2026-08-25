//
//  SimklModels.swift
//  Cronica
//

import Foundation

enum SimklMediaKind: String, Codable {
    case movies
    case shows
    case anime
}

enum SimklWatchStatus: String, Codable {
    case watching
    case plantowatch
    case hold
    case dropped
    case completed
}

struct SimklAllItemsResponse: Decodable {
    var movies: [SimklLibraryEntry]?
    var shows: [SimklLibraryEntry]?
    var anime: [SimklLibraryEntry]?
}

struct SimklLibraryEntry: Decodable {
    var status: SimklWatchStatus?
    var watchedEpisodesCount: Int?
    var totalEpisodesCount: Int?
    var userRating: Int?
    var lastWatchedAt: String?
    var movie: SimklMediaObject?
    var show: SimklMediaObject?
    var seasons: [SimklSeason]?
    var animeType: String?

    init(
        status: SimklWatchStatus? = nil,
        watchedEpisodesCount: Int? = nil,
        totalEpisodesCount: Int? = nil,
        userRating: Int? = nil,
        lastWatchedAt: String? = nil,
        movie: SimklMediaObject? = nil,
        show: SimklMediaObject? = nil,
        seasons: [SimklSeason]? = nil,
        animeType: String? = nil
    ) {
        self.status = status
        self.watchedEpisodesCount = watchedEpisodesCount
        self.totalEpisodesCount = totalEpisodesCount
        self.userRating = userRating
        self.lastWatchedAt = lastWatchedAt
        self.movie = movie
        self.show = show
        self.seasons = seasons
        self.animeType = animeType
    }

    enum CodingKeys: String, CodingKey {
        case status
        case watchedEpisodesCount = "watched_episodes_count"
        case totalEpisodesCount = "total_episodes_count"
        case userRating = "user_rating"
        case lastWatchedAt = "last_watched_at"
        case movie, show, seasons
        case animeType = "anime_type"
    }

    var mediaObject: SimklMediaObject? { movie ?? show }
}

struct SimklMediaObject: Decodable {
    var title: String?
    var year: Int?
    var ids: SimklIDs?

    init(title: String? = nil, year: Int? = nil, ids: SimklIDs? = nil) {
        self.title = title
        self.year = year
        self.ids = ids
    }
}

struct SimklIDs: Decodable {
    var simkl: Int?
    var tmdb: FlexibleID?
    var imdb: String?
    var tvdb: FlexibleID?
    var slug: String?

    init(
        simkl: Int? = nil,
        tmdb: FlexibleID? = nil,
        imdb: String? = nil,
        tvdb: FlexibleID? = nil,
        slug: String? = nil
    ) {
        self.simkl = simkl
        self.tmdb = tmdb
        self.imdb = imdb
        self.tvdb = tvdb
        self.slug = slug
    }
}

/// SIMKL returns some IDs as strings and others as ints.
enum FlexibleID: Decodable, Equatable {
    case int(Int)
    case string(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Int.self) {
            self = .int(value)
            return
        }
        if let value = try? container.decode(String.self) {
            self = .string(value)
            return
        }
        throw DecodingError.typeMismatch(
            FlexibleID.self,
            DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected Int or String")
        )
    }

    var intValue: Int? {
        switch self {
        case .int(let value): return value
        case .string(let value): return Int(value)
        }
    }
}

struct SimklSeason: Decodable {
    var number: Int?
    var episodes: [SimklEpisode]?

    init(number: Int? = nil, episodes: [SimklEpisode]? = nil) {
        self.number = number
        self.episodes = episodes
    }
}

struct SimklEpisode: Decodable {
    var number: Int?
    var watchedAt: String?

    init(number: Int? = nil, watchedAt: String? = nil) {
        self.number = number
        self.watchedAt = watchedAt
    }

    enum CodingKeys: String, CodingKey {
        case number
        case watchedAt = "watched_at"
    }

    var isWatched: Bool { watchedAt != nil }
}

struct SimklTokenResponse: Decodable {
    var accessToken: String
    var tokenType: String?
    var expiresIn: Int?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
    }
}

struct SimklPinResponse: Decodable {
    var result: String?
    var userCode: String
    var verificationUrl: String?
    var expiresIn: Int?
    var interval: Int?

    enum CodingKeys: String, CodingKey {
        case result
        case userCode = "user_code"
        case verificationUrl = "verification_url"
        case expiresIn = "expires_in"
        case interval
    }
}

struct SimklPinPollResponse: Decodable {
    var result: String?
    var accessToken: String?
    var tokenType: String?
    var expiresIn: Int?

    enum CodingKeys: String, CodingKey {
        case result
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
    }
}

struct SimklImportSummary: Equatable {
    var inserted = 0
    var updated = 0
    var skipped = 0
    var failed = 0
    var removedOnSimkl = 0
    var unchanged = false

    var totalProcessed: Int { inserted + updated + skipped + failed }
}

struct SimklActivitiesResponse: Decodable, Equatable {
    var all: String?
    var movies: SimklActivitiesBucket?
    var tvShows: SimklActivitiesBucket?
    var anime: SimklActivitiesBucket?

    enum CodingKeys: String, CodingKey {
        case all, movies, anime
        case tvShows = "tv_shows"
    }
}

struct SimklActivitiesBucket: Decodable, Equatable {
    var all: String?
    var watching: String?
    var plantowatch: String?
    var hold: String?
    var completed: String?
    var dropped: String?
    var removedFromList: String?

    enum CodingKeys: String, CodingKey {
        case all, watching, plantowatch, hold, completed, dropped
        case removedFromList = "removed_from_list"
    }
}

struct SimklWriteIds: Encodable {
    var tmdb: Int?
    var imdb: String?

    init(tmdb: Int? = nil, imdb: String? = nil) {
        self.tmdb = tmdb
        self.imdb = imdb
    }
}

struct SimklHistoryItem: Encodable {
    var ids: SimklWriteIds
    var watchedAt: String?
    var seasons: [SimklHistorySeason]?

    enum CodingKeys: String, CodingKey {
        case ids
        case watchedAt = "watched_at"
        case seasons
    }
}

struct SimklHistorySeason: Encodable {
    var number: Int
    var episodes: [SimklHistoryEpisode]
}

struct SimklHistoryEpisode: Encodable {
    var number: Int
}

struct SimklHistoryPayload: Encodable {
    var movies: [SimklHistoryItem]?
    var shows: [SimklHistoryItem]?
}

struct SimklAddToListPayload: Encodable {
    var to: String
    var movies: [SimklHistoryItem]?
    var shows: [SimklHistoryItem]?
}

struct SimklEmptyResponse: Decodable {}

enum SimklError: LocalizedError {
    case notConfigured
    case notAuthenticated
    case cancelled
    case invalidResponse
    case httpStatus(Int)
    case rateLimited
    case message(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return String(localized: "SIMKL is not configured. Add SIMKL_CLIENT_ID in Secrets.xcconfig.")
        case .notAuthenticated:
            return String(localized: "Connect your SIMKL account to continue.")
        case .cancelled:
            return String(localized: "Sign-in was cancelled.")
        case .invalidResponse:
            return String(localized: "Unexpected response from SIMKL.")
        case .httpStatus(let code):
            return String(localized: "SIMKL request failed (\(code)).")
        case .rateLimited:
            return String(localized: "SIMKL is busy. Try again in a moment.")
        case .message(let text):
            return text
        }
    }
}
