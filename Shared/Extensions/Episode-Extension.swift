//
//  Episode-Extension.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 06/04/22.
//

import Foundation

extension Episode {
	// MARK: Strings
	var itemTitle: String {
		if let name { return name }
		return String(localized: "Not Available")
	}
	var itemOverview: String {
		if let overview {
			if !overview.isEmpty { return overview }
		}
		return String()
	}
	var itemDate: String? {
		if let airDate, let date = airDate.toDate() {
			return date.convertDateToString()
		}
		return nil
	}
	var itemInfo: String? {
        let localizedString = String(localized: "Episode")
		if let itemDate, let episodeNumber {
			return "\(localizedString) \(episodeNumber) • \(itemDate)"
		}
		if let episodeNumber {
			return "\(localizedString) \(episodeNumber)"
		}
		return nil
	}
	var itemEpisodeNumberDisplay: Int {
		guard let episodeNumber else { return 0 }
		return episodeNumber
	}
	var itemEpisodeNumber: Int {
		guard let episodeNumber else { return 0 }
		return episodeNumber
	}
	
	var itemSeasonNumber: Int {
		guard let seasonNumber else { return 0 }
		return seasonNumber
	}
	
	var isItemReleased: Bool {
		guard let airDate else { return false }
		let date = DatesManager.dateFormatter.date(from: airDate)
		guard let date else { return false }
		return Date() >= date
	}
    
	// MARK: URL
    var itemImageSmall: URL? {
        return NetworkService.urlBuilder(size: .small, path: stillPath)
    }
	var itemImageMedium: URL? {
#if os(tvOS)
		return NetworkService.urlBuilder(size: .w780, path: stillPath)
#else
		return NetworkService.urlBuilder(size: .w500, path: stillPath)
#endif
	}
	var itemImageLarge: URL? {
		return NetworkService.urlBuilder(size: .large, path: stillPath)
	}
	var itemImageOriginal: URL? {
		return NetworkService.urlBuilder(size: .original, path: stillPath)
	}
	
	// MARK: Custom
	var itemNotificationID: String {
		return "\(id)@\(MediaType.tvShow.toInt)"
	}
}
