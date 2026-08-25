//
//  NetworkService.swift
//  Cronica
//
//  Created by Alexandre Madeira on 20/01/22.
//  swiftlint:disable trailing_whitespace

import Foundation

public final class NetworkService: Sendable {
    public static let shared = NetworkService()
    private let decoder = JSONDecoder()
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy,MM,dd"
        return formatter
    }()
    
    private init() {
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .formatted(NetworkService.dateFormatter)
    }
    
    public func fetchItem(id: ItemContent.ID, type: MediaType) async throws -> ItemContent {
        if UITestingConfiguration.usesMockData {
            return try mockItem(id: id, type: type)
        }
        if id == 0 {
            throw NetworkError.contentRemoved
        }
        guard let url = urlBuilder(path: "\(type.rawValue)/\(id)", append: type.append) else {
            throw NetworkError.invalidEndpoint
        }
        return try await self.fetch(url: url)
    }

    public func fetchSeason(id: Int, season: Int) async throws -> Season {
        guard let url = urlBuilder(path: "\(MediaType.tvShow.rawValue)/\(id)/season/\(season)") else {
            throw NetworkError.invalidEndpoint
        }
        return try await self.fetch(url: url)
    }
    
    public func fetchEpisode(tvID: Int64, season: Int64, episodeNumber: Int64) async throws -> Episode {
        guard let url = urlBuilder(path: "tv/\(tvID)/season/\(season)/episode/\(episodeNumber)") else {
            throw NetworkError.invalidRequest
        }
        return try await self.fetch(url: url)
    }
    
    public func fetchItems(from path: String, page: String = "1") async throws -> [ItemContent] {
        if UITestingConfiguration.usesMockData {
            return UITestingConfiguration.mockItems
        }
        guard let url = urlBuilder(path: path, page: page) else {
            throw NetworkError.invalidEndpoint
        }
        let response: ItemContentResponse = try await self.fetch(url: url)
        return response.results
    }
    
    public func fetchYearContent(year: String, type: MediaType, page: Int = 1) async throws -> [ItemContent] {
        guard let url = urlBuilder(type: type.rawValue,
                                   page: page,
                                   genres: nil,
                                   sortBy: .popularity,
                                   year: year) else {
            throw NetworkError.invalidRequest
        }
        let response: ItemContentResponse = try await self.fetch(url: url)
        return response.results
    }
	
	public func fetchPersons(from path: String, page: String = "1") async throws -> [Person] {
		guard let url = urlBuilder(path: path, page: page) else {
			throw NetworkError.invalidEndpoint
		}
		let response: PersonsResponse = try await self.fetch(url: url)
		return response.results ?? []
	}
    
    public func fetchCompanyFilmography(type: MediaType, page: Int, company: Int) async throws -> [ItemContent] {
		guard let url = urlBuilder(type: type, company: company, page: page, sortBy: TMDBSortBy.popularity.rawValue) else {
            throw NetworkError.invalidRequest
        }
        let response: ItemContentResponse = try await self.fetch(url: url)
        return response.results
    }
	
	public func fetchKeyword(type: MediaType, page: Int, keywords: Int, sortBy: String) async throws -> [ItemContent] {
		guard let url = urlBuilder(type: type, page: page, keywords: keywords, sortBy: sortBy) else {
			throw NetworkError.invalidRequest
		}
		let response: ItemContentResponse = try await self.fetch(url: url)
		return response.results
	}
    
    public func fetchDiscover(type: MediaType, page: Int, genres: String, sort: TMDBSortBy) async throws -> [ItemContent] {
        guard let url = urlBuilder(type: type.rawValue, page: page, genres: genres, sortBy: sort, year: nil) else {
            throw NetworkError.invalidEndpoint
        }
        let response: ItemContentResponse = try await self.fetch(url: url)
        return response.results
    }
    
    public func fetchKeywords(type: MediaType, id: Int) async throws -> [ItemContentKeyword] {
        guard let url = URL(string: "https://api.themoviedb.org/3/\(type.rawValue)/\(id)/keywords?api_key=\(Key.tmdbApi)")
        else {
            throw NetworkError.invalidRequest
        }
        // Some titles have no keywords resource (404) — treat as empty, don't error-log.
        guard let response: Keywords = try await self.fetch(url: url, ignoreStatusCodes: [404]) else {
            return []
        }
        return response.keywords
    }
    
    public func fetchPerson(id: Person.ID) async throws -> Person {
        guard let url = urlBuilder(path: "person/\(id)", append: "\(MediaType.person.append)")
        else {
            throw NetworkError.invalidEndpoint
        }
        return try await self.fetch(url: url)
    }
    
    public func fetchProviders(id: ItemContent.ID, for media: MediaType) async throws -> WatchProviders {
        guard let url = urlBuilder(path: "\(media.rawValue)/\(id)/watch/providers")
        else {
            throw NetworkError.invalidRequest
        }
        return try await self.fetch(url: url)
    }
    
    public func fetchWatchProviderServices(for type: MediaType, region: String) async throws -> WatchProviderResultContent {
        let url = URL(string: "https://api.themoviedb.org/3/watch/providers/\(type.rawValue)?api_key=\(Key.tmdbApi)&watch_region=\(region)")
        guard let url
        else {
            throw NetworkError.invalidRequest
        }
        return try await self.fetch(url: url)
    }

    public func fetchReviews(id: Int, type: MediaType, page: Int = 1) async throws -> TMDBReviewsResponse {
        guard type != .person else { throw NetworkError.invalidRequest }
        guard let url = urlBuilder(path: "\(type.rawValue)/\(id)/reviews", page: "\(page)") else {
            throw NetworkError.invalidEndpoint
        }
        return try await fetch(url: url)
    }

    public func downloadData(from url: URL) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
        return data
    }

    public func search(query: String, page: String) async throws -> [SearchItemContent] {
        if UITestingConfiguration.usesMockData {
            guard !query.isEmpty else { return [] }
            return UITestingConfiguration.mockItems
                .filter { $0.itemTitle.localizedCaseInsensitiveContains(query) }
                .map { item in
                    SearchItemContent(
                        adult: item.adult,
                        id: item.id,
                        title: item.title,
                        name: item.name,
                        overview: item.overview,
                        originalTitle: item.originalTitle,
                        posterPath: item.posterPath,
                        backdropPath: item.backdropPath,
                        profilePath: item.profilePath,
                        releaseDate: item.releaseDate,
                        status: item.status,
                        imdbId: item.imdbId,
                        runtime: item.runtime,
                        numberOfEpisodes: item.numberOfEpisodes,
                        numberOfSeasons: item.numberOfSeasons,
                        voteCount: item.voteCount,
                        popularity: item.popularity,
                        voteAverage: item.voteAverage,
                        releaseDates: item.releaseDates,
                        mediaType: item.mediaType,
                        nextEpisodeToAir: item.nextEpisodeToAir,
                        lastEpisodeToAir: item.lastEpisodeToAir,
                        originalName: item.originalName,
                        firstAirDate: item.firstAirDate,
                        homepage: item.homepage
                    )
                }
        }
        guard let url = urlBuilder(path: "search/multi", query: query, page: page) else {
            throw NetworkError.invalidEndpoint
        }
        let results: SearchItemContentResponse = try await self.fetch(url: url)
        return results.results
    }
    
    private func fetch<T: Decodable>(url: URL, ignoreStatusCodes: Set<Int> = []) async throws -> T? {
        guard Key.isConfigured else {
            AppLogger.network.error("TMDb API key is not configured")
            throw NetworkError.invalidApi
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }
        if ignoreStatusCodes.contains(httpResponse.statusCode) {
            return nil
        }
        let responseError = handleNetworkResponses(response: httpResponse)
        if let responseError {
            AppLogger.network.error("Network request failed with status \(httpResponse.statusCode): \(Self.redactedURL(url))")
            throw responseError
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            AppLogger.network.error("Failed to decode response from \(Self.redactedURL(url)): \(error.localizedDescription)")
            throw NetworkError.decodingError
        }
    }

    private func fetch<T: Decodable>(url: URL) async throws -> T {
        guard let value: T = try await fetch(url: url, ignoreStatusCodes: []) else {
            throw NetworkError.invalidResponse
        }
        return value
    }

    /// Avoid leaking the TMDb API key into console / crash logs.
    private static func redactedURL(_ url: URL) -> String {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return "<invalid-url>"
        }
        components.queryItems = components.queryItems?.map { item in
            item.name == "api_key" ? URLQueryItem(name: "api_key", value: "…") : item
        }
        return components.string ?? url.absoluteString
    }
    
    private func handleNetworkResponses(response: HTTPURLResponse) -> NetworkError? {
        switch response.statusCode {
        case 200...299: return nil
        case 401: return .invalidApi
        case 404: return .contentRemoved
        case 429: return .maintenanceApi
        case 503: return .maintenanceApi
        case 500...599: return .internalError
        default: return .invalidResponse
        }
    }
    
	public func urlBuilder(type: MediaType, company: Int? = nil, page: Int, keywords: Int? = nil, sortBy: String) -> URL? {
        var component = URLComponents()
        component.scheme = "https"
        component.host = "api.themoviedb.org"
        component.path = "/3/discover/\(type.rawValue)"
        var queryItems: [URLQueryItem] = [
            .init(name: "api_key", value: Key.tmdbApi),
            .init(name: "language", value: Locale.userLang),
            .init(name: "region", value: Locale.userRegion),
            .init(name: "sort_by", value: sortBy),
            .init(name: "include_adult", value: "false"),
            .init(name: "include_video", value: "false"),
            .init(name: "page", value: "\(page)")
        ]
        if let company {
            queryItems.append(.init(name: "with_companies", value: "\(company)"))
        }
        if let keywords {
            queryItems.append(.init(name: "with_keywords", value: "\(keywords)"))
        }
        component.queryItems = queryItems
        return component.url
    }
    
    /// Build a safe URL for the TMDB API Service.
    ///
    /// Only use it to generate the URL responsible for fetching content, such as details, lists, and search.
    /// - Parameters:
    ///   - path: The path for the fetch request.
    ///   - append: Additional information to fetch.
    ///   - query: The query for the search functionality, if in Search.
    /// - Returns: Returns nil if the path is nil, otherwise return a safe URL.
    private func urlBuilder(path: String, append: String? = nil, query: String? = nil, page: String = "1") -> URL? {
        var component = URLComponents()
        component.scheme = "https"
        component.host = "api.themoviedb.org"
        component.path = "/3/\(path)"
        if let append {
            component.queryItems = [
                .init(name: "api_key", value: Key.tmdbApi),
                .init(name: "language", value: Locale.userLang),
                .init(name: "page", value: page),
                .init(name: "append_to_response", value: append)
            ]
        } else {
            component.queryItems = [
                .init(name: "api_key", value: Key.tmdbApi),
                .init(name: "language", value: Locale.userLang),
                .init(name: "region", value: Locale.userRegion),
                .init(name: "page", value: page)
            ]
        }
        if let query {
            component.queryItems = [
                .init(name: "api_key", value: Key.tmdbApi),
                .init(name: "language", value: Locale.userLang),
                .init(name: "query", value: query),
                .init(name: "page", value: page),
                .init(name: "include_adult", value: "false"),
                .init(name: "region", value: Locale.userRegion)
            ]
        }
        return component.url
    }
    
    /// Build a safe URL for the TMDb's Discovery endpoint.
    /// - Parameters:
    ///   - type: The content type for the discovery fetch.
    ///   - page: The page used for pagination.
    ///   - genres: The desired genres for the discovery.
    private func urlBuilder(type: String, page: Int, genres: String?, sortBy: TMDBSortBy, year: String?) -> URL? {
        var component = URLComponents()
        component.scheme = "https"
        component.host = "api.themoviedb.org"
        component.path = "/3/discover/\(type)"
        if let year {
            component.queryItems = [
                .init(name: "api_key", value: Key.tmdbApi),
                .init(name: "language", value: Locale.userLang),
                .init(name: "region", value: Locale.userRegion),
                .init(name: "sort_by", value: sortBy.rawValue),
                .init(name: "include_adult", value: "false"),
                .init(name: "include_video", value: "false"),
                .init(name: "page", value: "\(page)"),
                .init(name: "year", value: year)
            ]
        } else {
            component.queryItems = [
                .init(name: "api_key", value: Key.tmdbApi),
                .init(name: "language", value: Locale.userLang),
                .init(name: "region", value: Locale.userRegion),
                .init(name: "sort_by", value: sortBy.rawValue),
                .init(name: "include_adult", value: "false"),
                .init(name: "include_video", value: "false"),
                .init(name: "page", value: "\(page)"),
                .init(name: "with_genres", value: genres)
            ]
        }
        return component.url
    }
    
    /// Build a safe URL for the images used on TMDB API.
    ///
    /// Use it only to build the URLs responsible for the images.
    /// - Parameters:
    ///   - size: The image size returned in the URL.
    ///   - path: The path for the image.
    /// - Returns: Returns nil if the path is nil, otherwise return a safe URL.
    public static func urlBuilder(size: ImageSize, path: String? = nil) -> URL? {
        if let path {
            var component = URLComponents()
            component.scheme = "https"
            component.host = "image.tmdb.org"
            component.path = "/\(size.rawValue)\(path)"
            return component.url
        }
        return nil
    }
    
    public static func fetchVideos(for videos: [VideosResult]? = nil) -> [VideoItem]? {
        guard let videos else { return nil }
        var items: [VideoItem] = []
        for video in videos {
            if video.isTrailer {
                items.append(VideoItem.init(url: urlBuilder(video: video.key),
                                            thumbnail: fetchThumbnail(for: video.key),
                                            title: video.name, videoID: video.key))
            }
        }
        return items
    }
    
    /// Build a URL for the trailer, only generate YouTube links.
    /// - Parameter path: The 'key' for the trailer.
    /// - Returns: Returns nil if the path is nil, otherwise return a safe URL.
    private static func urlBuilder(video path: String? = nil) -> URL? {
        guard let path else { return nil }
        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.youtube.com"
        components.path = "/embed/\(path)"
        return components.url
    }
    
    private static func fetchThumbnail(for id: String?) -> URL? {
        guard let id else { return nil }
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "img.youtube.com"
        urlComponents.path = "/vi/\(id)/mqdefault.jpg"
        return urlComponents.url
    }

    private func mockItem(id: ItemContent.ID, type: MediaType) throws -> ItemContent {
        let items = UITestingConfiguration.mockItems
        if let match = items.first(where: { $0.id == id && $0.itemContentMedia == type }) {
            return match
        }
        if let match = items.first(where: { $0.id == id }) {
            return match
        }
        if let first = items.first {
            return first
        }
        throw NetworkError.contentRemoved
    }
}
