//
//  ItemContentSection.swift
//  Cronica
//

import Foundation

struct ItemContentSection: Identifiable, Sendable {
    var id = UUID()
    let results: [ItemContent]
    let endpoint: Endpoints

    init(results: [ItemContent], endpoint: Endpoints) {
        self.results = results
        self.endpoint = endpoint
    }

    var title: String { endpoint.title }
    var subtitle: String { endpoint.subtitle }
}
