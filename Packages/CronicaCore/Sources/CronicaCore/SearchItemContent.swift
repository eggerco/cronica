//
//  SearchItem.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 10/08/23.
//

import Foundation

public struct SearchItemContent: Identifiable, Codable, Hashable {
	public let adult: Bool?
	public let id: Int
	public let title, name, overview, originalTitle: String?
	public let posterPath, backdropPath, profilePath: String?
	public let releaseDate, status, imdbId: String?
	public let runtime, numberOfEpisodes, numberOfSeasons, voteCount: Int?
	public let popularity, voteAverage: Double?
	public let releaseDates: ReleaseDates?
	public let mediaType: String?
	public var nextEpisodeToAir, lastEpisodeToAir: Episode?
	public let originalName, firstAirDate, homepage: String?
}

public struct SearchItemContentResponse: Identifiable, Codable, Hashable {
	public let id: String?
	public let results: [SearchItemContent]
}
