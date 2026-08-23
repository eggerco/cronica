//
//  DatesManager.swift
//  Cronica
//
//  Created by Alexandre Madeira on 05/02/23.
//

import Foundation

/// Migrate to extension based formatters and functions to get release dates and format the result.
public class DatesManager {
	public static let decoder: JSONDecoder = {
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		decoder.dateDecodingStrategy = .formatted(dateFormatter)
		return decoder 
	}()
	public static let dateFormatter: DateFormatter = {
		let formatter = DateFormatter()
        formatter.timeZone = .current
		formatter.dateFormat = "y,MM,dd"
		return formatter
	}()
	public static let dateString: DateFormatter = {
		let formatter = DateFormatter()
        formatter.timeZone = .current
		formatter.dateStyle = .medium
		formatter.timeStyle = .none
		return formatter
	}()
	private static var releaseDateFormatter: ISO8601DateFormatter {
		let formatter = ISO8601DateFormatter()
        formatter.timeZone = .current
		formatter.formatOptions = .withFullDate
		return formatter
	}
	public static func getDetailedReleaseDateFormatted(results: [ReleaseDatesResult], productionRegion: String) -> String? {
		if results.isEmpty { return nil }
		if results.contains(where: { $0.iso31661?.lowercased() == Locale.userRegion.lowercased() }) {
			let result = results.filter { $0.iso31661?.lowercased()  == Locale.userRegion.lowercased() }.first
			guard let dates = result?.releaseDates else { return nil }
			var content: String?
			if dates.contains(where: { $0.type == ReleaseDateType.theatrical.toInt }) {
				guard let theatrical = dates.filter({ $0.type == ReleaseDateType.theatrical.toInt }).first else { return nil }
				content = theatrical.releaseDate
			} else {
				guard let firstDateAvailable = dates.first else { return nil }
				content = firstDateAvailable.releaseDate
			}
			guard let content else { return nil }
			guard let releaseDate = releaseDateFormatter.date(from: content) else { return nil }
			return dateString.string(from: releaseDate)
		} else if results.contains(where: { $0.iso31661?.lowercased() == productionRegion.lowercased() }) {
			let result = results.filter { $0.iso31661?.lowercased()  == productionRegion.lowercased() }.first
			guard let dates = result?.releaseDates else { return nil }
			var content: String?
			if dates.contains(where: { $0.type == ReleaseDateType.theatrical.toInt }) {
				guard let theatrical = dates.filter({ $0.type == ReleaseDateType.theatrical.toInt }).first else { return nil }
				content = theatrical.releaseDate
			} else {
				guard let firstDateAvailable = dates.first else { return nil }
				content = firstDateAvailable.releaseDate
			}
			guard let content else { return nil }
			guard let releaseDate = releaseDateFormatter.date(from: content) else { return nil }
			return dateString.string(from: releaseDate)
		}
		let result = results.filter { $0.iso31661?.lowercased()  == "US".lowercased() }.first
		guard let dates = result?.releaseDates else { return nil }
		var content: String?
		if dates.contains(where: { $0.type == ReleaseDateType.theatrical.toInt }) {
			guard let theatrical = dates.filter({ $0.type == ReleaseDateType.theatrical.toInt }).first else { return nil }
			content = theatrical.releaseDate
		} else {
			guard let firstDateAvailable = dates.first else { return nil }
			content = firstDateAvailable.releaseDate
		}
		guard let content else { return nil }
		guard let releaseDate = releaseDateFormatter.date(from: content) else { return nil }
		return dateString.string(from: releaseDate)
	}
}
