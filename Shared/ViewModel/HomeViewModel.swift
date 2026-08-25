//
//  HomeViewModel.swift
//  Cronica
//
//  Created by Alexandre Madeira on 02/03/22.
//

import CoreData
import SwiftUI

#if !os(watchOS)
@MainActor
class HomeViewModel: ObservableObject {
    private let service: NetworkService = NetworkService.shared
    @Published var featured = [ItemContent]()
    /// Remote TMDB rails keyed by endpoint.
    @Published var sectionResults: [Endpoints: [ItemContent]] = [:]
    @Published var isLoaded = false

    func load(visibleKinds: [HomeSectionKind]) async {
        let needsFeatured = visibleKinds.contains(.featured)
        if needsFeatured, featured.isEmpty {
            do {
                let result = try await service.fetchItems(from: "trending/all/day")
                featured = Self.filterFeaturedItems(result)
            } catch {
                if Task.isCancelled { return }
                CronicaTelemetry.shared.handleMessage(error.localizedDescription, for: "HomeViewModel.load.featured")
            }
        }

        let endpoints = visibleKinds.compactMap(\.endpoint)
        for endpoint in endpoints where sectionResults[endpoint] == nil {
            if let section = await fetch(from: endpoint) {
                sectionResults[endpoint] = section.results
            }
        }

        await MainActor.run {
            withAnimation { self.isLoaded = true }
        }
    }

    func reload() {
        withAnimation {
            isLoaded = false
        }
        featured.removeAll()
        sectionResults.removeAll()
        Task {
            await load(visibleKinds: HomeSectionStore.shared.visibleOrderedSections)
        }
    }

    /// Fetch an Endpoint value.
    private func fetch(from endpoint: Endpoints) async -> ItemContentSection? {
        do {
            let section = try await service.fetchItems(from: endpoint.path)
            let filtered = section.filter { $0.backdropPath != nil && $0.posterPath != nil }
            return .init(results: filtered, endpoint: endpoint)
        } catch {
            if Task.isCancelled { return nil }
            CronicaTelemetry.shared.handleMessage(error.localizedDescription, for: "HomeViewModel.fetchSection.\(endpoint)")
            return nil
        }
    }

    static func filterFeaturedItems(_ items: [ItemContent]) -> [ItemContent] {
        items
            .filter { $0.itemContentMedia != .person }
            .filter { $0.posterPath != nil }
            .sorted { $0.itemPopularity > $1.itemPopularity }
    }
}
#endif
