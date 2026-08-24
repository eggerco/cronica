//
//  Content-Helpers.swift
//  Cronica
//
//  Created by Alexandre Madeira on 06/03/22.
//  swiftlint:disable trailing_whitespace

import Foundation

public extension ItemContent {
    // MARK: Strings
    var itemTitle: String {
        if let title { return title }
        if let name { return name }
        return NSLocalizedString("Not Available", comment: "")
    }
    var itemOverview: String {
        if let overview {
            if overview.isEmpty {
                return NSLocalizedString("No information available.", comment: "")
            } else {
                return overview
            }
        }
        return NSLocalizedString("No information available.", comment: "")
    }
    var itemGenre: String {
        if let genre = genres?.first?.name { return genre }
        return String()
    }
    var itemGenres: String {
        guard let genres = genres else { return String() }
        var genreTitles = [String]()
        for genre in genres {
            if let title = genre.name {
                genreTitles.append(title)
            }
        }
        if genreTitles.isEmpty { return String() }
        let output = genreTitles.joined(separator: ", ")
        return output
    }
    var itemCountry: String {
        if let country = productionCountries?.first?.name { return country }
        return NSLocalizedString("Not Available", comment: "")
    }
    var itemCompany: String {
        if let productionCompanies {
            var companies = [String]()
            for company in productionCompanies {
                companies.append(company.name)
            }
            if companies.isEmpty { return String() }
            let output = companies.joined(separator: ", ")
            return output
        }
        if let company = productionCompanies?.first?.name {
            return company
        }
        return NSLocalizedString("Not Available", comment: "")
    }
    var itemRuntime: String? {
        if let runtime {
            if runtime > 0 { return runtime.convertToLongRuntime() }
        }
        return nil
    }
    var shortItemRuntime: String? {
        if let runtime {
            if runtime > 0 { return runtime.convertToShortRuntime() }
        }
        return nil
    }
    var shortEpisodeAverageRuntime: String? {
        guard let runtime = episodeRunTime?.first else { return nil }
        if runtime > 0 { return runtime.convertToShortRuntime() }
        return nil
    }
    var longEpisodeAverageRuntime: String? {
        guard let runtime = episodeRunTime?.first else { return nil }
        if runtime > 0 { return runtime.convertToLongRuntime() }
        return nil
    }
    var itemContentID: String {
        return "\(id)@\(itemContentMedia.toInt)"
    }
    var itemTheatricalString: String? {
        if let dates = releaseDates?.results {
			var productionRegion = "US"
			if let country = productionCountries?.first {
				productionRegion = country.iso31661
			}
            return DatesManager.getDetailedReleaseDateFormatted(results: dates, productionRegion: productionRegion)
        }
		if let itemFirstAirDate {
			return "\(itemFirstAirDate)"
		}
        if let date = nextEpisodeDate {
            return "\(DatesManager.dateString.string(from: date))"
        }
        return nil
    }
    var itemInfo: String {
        if let itemTheatricalString, let shortItemRuntime {
            return "\(itemGenre) • \(itemTheatricalString) • \(shortItemRuntime)"
        }
        if let itemTheatricalString {
            return "\(itemGenres) • \(itemTheatricalString)"
        }
        if let date = nextEpisodeDate {
            return "\(itemGenres) • \(DatesManager.dateString.string(from: date))"
        }
        if let shortItemRuntime {
            return "\(itemGenres) • \(shortItemRuntime)"
        }
        if let itemFallbackDate {
            return "\(itemGenres) • \(DatesManager.dateString.string(from: itemFallbackDate))"
        }
        if let shortEpisodeAverageRuntime {
            return "\(itemGenres) • \(shortEpisodeAverageRuntime)"
        }
        if !itemGenres.isEmpty { return "\(itemGenres)" }
        return ""
    }
    var itemQuickInfo: String {
        if let itemTheatricalString, let shortItemRuntime {
            return "\(itemTheatricalString) • \(shortItemRuntime)"
        }
        if let itemTheatricalString {
            return "\(itemTheatricalString)"
        }
		if let itemFirstAirDate {
			return "\(itemFirstAirDate)"
		}
        if let date = nextEpisodeDate {
            return "\(DatesManager.dateString.string(from: date))"
        }
        if let shortItemRuntime {
            return "\(shortItemRuntime)"
        }
        if let itemFallbackDate {
            return "\(DatesManager.dateString.string(from: itemFallbackDate))"
        }
        return ""
    }
    var itemRating: String? {
        guard let voteAverage else { return nil }
        let formattedString = String(format: "%.1f", voteAverage)
        return "\(formattedString)/10"
    }
    
    // MARK: Double
    var itemPopularity: Double {
        popularity ?? 0.0
    }
    
    // MARK: Custom
    var itemStatus: ItemSchedule {
        if status == "Released" && itemCanNotify { return .soon }
        switch status {
        case "Rumored": return .production
        case "Planned": return .production
        case "In Production": return .soon
        case "Post Production": return .soon
        case "Returning Series": return .renewed
        case "Released": return .released
        case "Ended": return .ended
        case "Canceled": return .cancelled
        default: return .unknown
        }
    }
    /// This MediaType value is only used on regular content, such a trending list, filmography.
    ///
    /// Change to media to search results.
    var itemContentMedia: MediaType {
        if title != nil {
            return .movie
        } else {
            return .tvShow
        }
    }
    /// This MediaType value is only used on search results
    ///
    /// Change to itemContentMedia to specify on normal usage.
    var media: MediaType {
        switch mediaType {
        case "tv": return .tvShow
        case "movie": return .movie
        case "person": return .person
        default: return .movie
        }
    }
    var itemTrailers: [VideoItem] {
        guard let content = NetworkService.fetchVideos(for: videos?.results) else {
            return []
        }
        return content
    }
    var itemCompanies: [ProductionCompany] {
        guard let productionCompanies else { return [] }
        return productionCompanies
    }
    
    // MARK: URL
    var posterImageMedium: URL? {
#if os(tvOS)
        return NetworkService.urlBuilder(size: .w780, path: posterPath)
#else
        return NetworkService.urlBuilder(size: .w500, path: posterPath)
#endif
    }
    var posterImageLarge: URL? {
        return NetworkService.urlBuilder(size: .w500, path: posterPath)
    }
    var cardImageSmall: URL? {
        return NetworkService.urlBuilder(size: .small, path: backdropPath)
    }
    var cardImageMedium: URL? {
#if os(tvOS)
        return NetworkService.urlBuilder(size: .w780, path: backdropPath)
#else
        return NetworkService.urlBuilder(size: .w500, path: backdropPath)
#endif
    }
    var cardImageLarge: URL? {
        return NetworkService.urlBuilder(size: .large, path: backdropPath)
    }
    var cardImageOriginal: URL? {
        return NetworkService.urlBuilder(size: .original, path: backdropPath)
    }
    var castImage: URL? {
        return NetworkService.urlBuilder(size: .medium, path: profilePath)
    }
    var imdbUrl: URL? {
        guard let imdbId else { return nil }
        return URL(string: "https://www.imdb.com/title/\(imdbId)")
    }
    var itemImage: URL? {
#if os(tvOS)
        switch media {
        case .person: return castImage
        default: return posterImageMedium
        }
#else
        switch media {
        case .person: return castImage
        default: return cardImageSmall
        }
#endif
    }
    var itemURL: URL {
        URL(string: "https://www.themoviedb.org/\(itemContentMedia.rawValue)/\(id)")
            ?? URL(string: "https://www.themoviedb.org")!
    }
    
    // MARK: Bool
    var hasIMDbUrl: Bool {
        if imdbId != nil { return true }
        return false
    }
    var itemCanNotify: Bool {
        if let itemTheatricalDate {
            if itemTheatricalDate > Date() {
                return true
            }
        }
        if let nextEpisodeDate {
            if nextEpisodeDate > Date() {
                return true
            }
        }
        return false
    }
    var hasUpcomingSeason: Bool {
		guard let nextEpisodeToAir else { return false }
		if nextEpisodeToAir.episodeNumber == 1 && itemCanNotify {
			return true
		} else { return false }
    }
    var itemIsAdult: Bool {
        adult ?? false
    }
    var itemSearchDescription: String {
        if media == .person {
            return media.title
        }
        if let itemTheatricalString, shortItemRuntime != nil {
            return "\(itemContentMedia.title) • \(itemTheatricalString)"
        }
        if let itemTheatricalString {
            return "\(itemContentMedia.title) • \(itemTheatricalString)"
        }
        if let date = nextEpisodeDate {
            return "\(itemContentMedia.title) • \(DatesManager.dateString.string(from: date))"
        }
        if let itemFallbackDate {
            return "\(itemContentMedia.title) • \(DatesManager.dateString.string(from: itemFallbackDate))"
        }
        if let date = lastEpisodeToAir?.airDate {
            let formattedDate = DatesManager.dateFormatter.date(from: date)
            if let formattedDate {
                return "\(itemContentMedia.title) • \(DatesManager.dateString.string(from: formattedDate))"
            }
        }
        if let itemFirstAirDate {
            return "\(itemContentMedia.title) • \(itemFirstAirDate)"
        }
        return "\(itemContentMedia.title)"
    }
	var itemNotificationDescription: String {
		if itemContentMedia == .movie {
			if let itemTheatricalString, shortItemRuntime != nil {
				return "\(itemContentMedia.title) • \(itemTheatricalString)"
			}
			if let itemTheatricalString {
				return "\(itemContentMedia.title) • \(itemTheatricalString)"
			}
		}
		if let date = nextEpisodeDate {
			return "\(itemContentMedia.title) • \(DatesManager.dateString.string(from: date))"
		}
		if let date = lastEpisodeToAir?.airDate {
			let formattedDate = DatesManager.dateFormatter.date(from: date)
			if let formattedDate {
				return "\(itemContentMedia.title) • \(DatesManager.dateString.string(from: formattedDate))"
			}
		}
		if let itemFallbackDate {
			return "\(itemContentMedia.title) • \(DatesManager.dateString.string(from: itemFallbackDate))"
		}
		return "\(itemContentMedia.title)"
	}

    var originalItemTitle: String? {
        if let originalTitle { return originalTitle }
        if let originalName { return originalName }
        return nil
    }
    
    // MARK: Int
    var itemSeasons: [Int]? {
        guard let numberOfSeasons else { return nil }
        if numberOfSeasons == 0 { return nil }
        return Array(1...numberOfSeasons)
    }
    
    // MARK: Date
    var nextEpisodeDate: Date? {
        guard let nextEpisodeDate = nextEpisodeToAir?.airDate else { return nil }
        return DatesManager.dateFormatter.date(from: nextEpisodeDate)
    }
    
    var itemFirstAirDate: String? {
        guard let firstAirDate else { return nil }
        let date = DatesManager.dateFormatter.date(from: firstAirDate)
        guard let date else { return nil }
        return DatesManager.dateString.string(from: date)
    }
    
    var itemTheatricalDate: Date? {
        if let itemTheatricalString {
            return DatesManager.dateString.date(from: itemTheatricalString)
        }
        if let releaseDate = releaseDate {
            return DatesManager.dateFormatter.date(from: releaseDate)
        }
        return nil
    }
    var itemFallbackDate: Date? {
        if let itemTheatricalDate {
            return itemTheatricalDate
        }
        if let releaseDate = releaseDate {
            return DatesManager.dateFormatter.date(from: releaseDate)
        }
        if let lastEpisodeToAir, let date = lastEpisodeToAir.airDate {
            return DatesManager.dateFormatter.date(from: date)
        }
        return nil
    }
	var itemNotificationSortDate: Date? {
		if itemContentMedia == .movie {
			if let itemTheatricalDate {
				return itemTheatricalDate
			}
		}
		if let nextEpisodeDate {
			return nextEpisodeDate
		}
		if let releaseDate = releaseDate {
			return DatesManager.dateFormatter.date(from: releaseDate)
		}
		if let lastEpisodeToAir, let date = lastEpisodeToAir.airDate {
			return DatesManager.dateFormatter.date(from: date)
		}
		return nil
	}
    
    // MARK: Preview
    static var examples: [ItemContent] {
        let data: ItemContentResponse? = try? Bundle.main.decode(from: "content")
        return data?.results ?? []
    }
    static var example: ItemContent {
        if let first = examples.first { return first }
        return ItemContent(
            adult: nil, id: 0, title: "Example", name: nil, overview: nil, originalTitle: nil,
            posterPath: nil, backdropPath: nil, profilePath: nil, releaseDate: nil, status: nil, imdbId: nil,
            runtime: nil, numberOfEpisodes: nil, numberOfSeasons: nil, voteCount: nil,
            popularity: nil, voteAverage: nil, productionCompanies: nil, productionCountries: nil,
            seasons: nil, genres: nil, credits: nil, recommendations: nil, releaseDates: nil,
            mediaType: nil, videos: nil, nextEpisodeToAir: nil, lastEpisodeToAir: nil,
            originalName: nil, firstAirDate: nil, homepage: nil, episodeRunTime: nil,
            placeholderImagePath: nil
        )
    }

    static var widgetExamples: [ItemContent] {
        let data: ItemContentResponse? = try? Bundle.main.decode(from: "DataPlaceholder")
        if let results = data?.results {
            return results.map { item in
                var mapped = item
                switch item.id {
                case 72844: mapped.placeholderImagePath = "2"
                case 530915: mapped.placeholderImagePath = "3"
                case 137113: mapped.placeholderImagePath = "4"
                default: mapped.placeholderImagePath = "1"
                }
                return mapped
            }
        }
        return examples
    }
}
