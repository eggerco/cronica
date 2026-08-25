//
//  AggregateCredits.swift
//  CronicaCore
//

import Foundation

public struct AggregateCreditsResponse: Codable, Sendable {
    public let id: Int
    public let cast: [AggregateCastMember]
}

public struct AggregateCastMember: Codable, Sendable {
    public let adult: Bool?
    public let id: Int
    public let name: String
    public let profilePath: String?
    public let knownForDepartment: String?
    public let popularity: Double?
    public let roles: [AggregateCastRole]
}

public struct AggregateCastRole: Codable, Sendable {
    public let character: String?
}

public extension AggregateCastMember {
    func toPerson() -> Person {
        let character = roles
            .compactMap(\.character)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
        return Person(
            adult: adult,
            id: id,
            name: name,
            job: nil,
            character: character.isEmpty ? nil : character,
            biography: nil,
            profilePath: profilePath,
            knownForDepartment: knownForDepartment,
            combinedCredits: nil,
            popularity: popularity
        )
    }
}
