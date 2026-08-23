//
//  Credits.swift
//  Cronica
//
//  Created by Alexandre Madeira on 21/01/22.
//

import Foundation
import SwiftUI

public struct Credits: Codable, Hashable {
    public let cast, crew: [Person]
}
/// A model that represents a person.
public struct Person: Codable, Identifiable, Hashable, Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation(exporting: \.itemUrlProxy)
    }
    public let adult: Bool?
    public let id: Int
    public let name: String
    public let job, character, biography, profilePath: String?
    public let combinedCredits: Filmography?
    public let popularity: Double?
}
public struct Filmography: Codable, Hashable {
    public let cast, crew: [ItemContent]?
}
public struct PersonsResponse: Codable, Hashable {
	public let page: Int?
	public let results: [Person]?
}
