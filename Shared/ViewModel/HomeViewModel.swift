//
//  HomeViewModel.swift
//  Cronica
//
//  Created by Alexandre Madeira on 02/03/22.
//

import CoreData
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    private let service: NetworkService = NetworkService.shared
    @Published var trending = [ItemContent]()
    /// Remote TMDB rails keyed by endpoint.
    @Published var sectionResults: [Endpoints: [ItemContent]] = [:]
    @Published var isLoaded = false

    func load(visibleKinds: [HomeSectionKind]) async {
        let needsTrending = visibleKinds.contains(.trending)
        if needsTrending, trending.isEmpty {
            do {
                let result = try await service.fetchItems(from: "trending/all/day")
                let filtered = result.filter { $0.itemContentMedia != .person }
                trending = filtered
            } catch {
                if Task.isCancelled { return }
                CronicaTelemetry.shared.handleMessage(error.localizedDescription, for: "HomeViewModel.load.trending")
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
        trending.removeAll()
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
}

/// Theses keywords are used in some NSFW titles, this should be only used
/// for avoiding displaying such titles in recommendations lists, explore and search.
let nsfwKeywords = [155477, 230416, 190370, 158254, 159551, 301766]
