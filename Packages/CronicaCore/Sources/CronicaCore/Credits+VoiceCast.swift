//
//  Credits+VoiceCast.swift
//  CronicaCore
//

import Foundation

public enum VoiceCastFormatter {
    public static func sectionSubtitle(for languageCode: String = Locale.userLanguageCode) -> String? {
        guard let label = Locale.current.localizedString(forLanguageCode: languageCode) else { return nil }
        return label
    }

    public static func splitCast(_ cast: [Person]) -> (onScreen: [Person], voice: [Person]) {
        var voice: [Person] = []
        var onScreen: [Person] = []
        for person in cast {
            if person.isVoiceRole {
                voice.append(person)
            } else {
                onScreen.append(person)
            }
        }
        return (onScreen, voice)
    }

    public static func deduplicatedVoiceCast(_ people: [Person]) -> [Person] {
        var seen = Set<Int>()
        var result: [Person] = []
        for person in people where person.isVoiceRole {
            guard seen.insert(person.id).inserted else { continue }
            result.append(person)
        }
        return result
    }
}

public extension Array where Element == Person {
    var voiceCast: [Person] {
        VoiceCastFormatter.deduplicatedVoiceCast(filter(\.isVoiceRole))
    }

    var onScreenCast: [Person] {
        filter { !$0.isVoiceRole }
    }
}
