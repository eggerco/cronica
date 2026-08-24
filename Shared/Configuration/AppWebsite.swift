//
//  AppWebsite.swift
//  Cronica
//

import Foundation

enum AppWebsite {
    static let baseURL = URL(string: "https://cronica.eggerco.com")!

    static var privacyPolicy: URL {
        baseURL.appending(path: "privacy")
    }

    static func detailsURL(contentID: String, posterPath: String?, title: String) -> URL? {
        let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let encodedPoster = (posterPath ?? "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        var components = URLComponents(url: baseURL.appending(path: "details"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "id", value: contentID),
            URLQueryItem(name: "img", value: encodedPoster),
            URLQueryItem(name: "title", value: encodedTitle)
        ]
        return components?.url
    }
}
