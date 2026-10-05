//
//  SearchView.swift
//  Cronica Watch App
//
//  Created by Alexandre Madeira on 07/08/23.
//

import SwiftUI

struct TrendingView: View {
    static let tag: Screens? = .trending
    private let service: NetworkService = NetworkService.shared
    @State private var trending = [ItemContent]()
    @State private var isLoaded = false
    @State private var showError = false
    @State private var catalogFailure: TMDBConnectionFailure?
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if showError && trending.isEmpty {
                        TMDBCatalogUnavailableView(failure: catalogFailure) {
                            load(force: true)
                        }
                    } else {
                        List {
                            ForEach(trending) { item in
                                NavigationLink(value: item) {
                                    ItemContentRow(item: item)
                                }
                            }
                        }
                        .redacted(reason: isLoaded ? [] : .placeholder)
                    }
                }
            }
            .cronicaLoadingOverlay(!isLoaded && !showError)
            .navigationTitle("Trending")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: ItemContent.self) { item in
                ItemContentView(id: item.id,
                                title: item.itemTitle,
                                type: item.itemContentMedia,
                                image: item.cardImageMedium)
            }
            .onAppear { load() }
        }
    }
    
    private func load(force: Bool = false) {
        Task {
            if isLoaded && !force { return }
            showError = false
            catalogFailure = nil
            if force {
                isLoaded = false
            }
            do {
                let result = try await service.fetchItems(from: "trending/all/day")
                let filtered = result.filter { $0.itemContentMedia != .person }
                trending = filtered
                isLoaded = true
            } catch {
                if Task.isCancelled { return }
                showError = trending.isEmpty
                catalogFailure = TMDBConnectionFailure.classify(error)
                isLoaded = true
            }
        }
    }
}

#Preview {
    TrendingView()
}
