//
//  Date-Extensions.swift
//  Cronica
//
//  Created by Alexandre Madeira on 04/11/22.
//

import Foundation

public extension Date {
    static let toDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "y,MM,dd"
        return formatter
    }()
    static let toStringFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    func convertDateToString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeZone = .current
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    func convertDateToShortString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeZone = .current
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    func isLessThanTwoWeeksAway() -> Bool {
        let today = Date()
        let twoMonths = TimeInterval(14 * 24 * 60 * 60)
        if self < (today + twoMonths) { return true }
        return false
    }
    func hasPassedTwoWeek() -> Bool {
        let today = Date()
        let week = TimeInterval(14 * 24 * 60 * 60)
        if today > (self + week) { return true }
        return false
    }
    func hasPassedFourWeeks() -> Bool {
        let today = Date()
        let week = TimeInterval(28 * 24 * 60 * 60)
        if today > (self + week) { return true }
        return false
    }
    func toShortString() -> String {

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd"

        let dateString = dateFormatter.string(from: self)
        return dateString
    }
}

public extension Date? {
    /// This function calculates if the given date is less than two months away from today.
    func isLessThanTwoWeeksAway() -> Bool {
        if let date = self {
            let today = Date()
            let twoMonths = TimeInterval(14 * 24 * 60 * 60)
            if date < (today + twoMonths) { return true }
        }
        return false
    }
    
    func hasPassedFourDays() -> Bool {
        if let date = self {
            let today = Date()
            let week = TimeInterval(4 * 24 * 60 * 60)
            if today > (date + week) { return true }
        }
        return false
    }
    
    func hasPassedTwoWeek() -> Bool {
        if let date = self {
            let today = Date()
            let week = TimeInterval(14 * 24 * 60 * 60)
            if today > (date + week) { return true }
        }
        return false
    }
    
    func areDifferentDates(with new: Date?) -> Bool {
        if let original = self, let new {
            if original != new { return true }
        }
        return false
    }
}
