//
//  Locale-Extensions.swift
//  Cronica
//
//  Created by Alexandre Madeira on 03/02/23.
//

import Foundation

public extension Locale {
    static var userLang: String {
        let locale = Locale.current
        guard let langCode = locale.language.languageCode?.identifier,
              let regionCode = locale.language.region?.identifier else {
            return "en-US"
        }
        return "\(langCode)-\(regionCode)"
    }
    
    static var userRegion: String {
        guard let region = Locale.current.language.region?.identifier else {
            return "US"
        }
        return region
    }
}
