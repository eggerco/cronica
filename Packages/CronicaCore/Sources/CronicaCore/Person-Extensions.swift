//
//  Person-Extensions.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 24/03/22.
//

import Foundation

public extension Person {
    var isAdult: Bool {
        adult ?? true
    }
    var personImage: URL? {
        return NetworkService.urlBuilder(size: .medium, path: profilePath)
    }
    var originalPersonImage: URL? {
        return NetworkService.urlBuilder(size: .original, path: profilePath)
    }
    var hasBiography: Bool {
        guard let biography else { return false }
        if !biography.isEmpty { return true }
        return false
    }
    var personBiography: String {
        if let biography {
            if biography.isEmpty {
                return String(localized: "No biography available.", bundle: .main)
            }
            return biography
        }
        return String(localized: "No biography available.", bundle: .main)
    }
    var personRole: String? {
        let base = job ?? character
        guard let base, !base.isEmpty else {
            return isVoiceRole ? String(localized: "Voice", bundle: .main) : nil
        }
        if isVoiceRole, !base.localizedCaseInsensitiveContains("voice") {
            let voice = String(localized: "Voice", bundle: .main)
            return "\(voice) • \(base)"
        }
        return base
    }
    var isVoiceRole: Bool {
        if matchesVoiceKeyword(job) { return true }
        if matchesVoiceKeyword(character) { return true }
        if let knownForDepartment,
           knownForDepartment.localizedCaseInsensitiveContains("Actors")
            || knownForDepartment.localizedCaseInsensitiveContains("Acting") {
            if matchesVoiceKeyword(character) { return true }
        }
        return false
    }

    private func matchesVoiceKeyword(_ value: String?) -> Bool {
        guard let value else { return false }
        let normalized = value.localizedLowercase
        return Self.voiceKeywords.contains { normalized.contains($0) }
    }

    private static let voiceKeywords = [
        "voice",
        "(voice)",
        "stimme",
        "synchron",
        "dubbing",
        "voix",
        "voz",
        "doppiat"
    ]
    var itemPopularity: Double {
        return popularity ?? 0.00
    }
    var itemURL: URL {
        URL(string: "https://www.themoviedb.org/person/\(id)")
            ?? URL(string: "https://www.themoviedb.org")!
    }
    var itemUrlProxy: String {
        return  "https://www.themoviedb.org/person/\(id)"
    }
    var personListID: String {
        if let personRole { return "\(id)\(personRole)" }
        return "\(id)"
    }
    static var example: [Person] {
        ItemContent.example.credits?.cast ?? []
    }
    static var previewCast: Person {
        example.first ?? Person(
            adult: nil, id: 0, name: "Preview", job: nil, character: nil,
            biography: nil, profilePath: nil, knownForDepartment: nil, combinedCredits: nil, popularity: nil
        )
    }
}
