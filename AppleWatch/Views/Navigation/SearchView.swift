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
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(trending) { item in
                        NavigationLink(value: item) {
                            ItemContentRow(item: item)
                        }
                    }
                } header: {
                    Text("Today")
                        .font(CronicaDesign.Typography.caption())
                        .textCase(.uppercase)
                        .foregroundStyle(.secondary)
                }
            }
            .redacted(reason: isLoaded ? [] : .placeholder)
            .overlay { if !isLoaded { CronicaLoadingPopupView() } }
            .navigationTitle("Trending")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: ItemContent.self) { item in
                ItemContentView(id: item.id,
                                title: item.itemTitle,
                                type: item.itemContentMedia,
                                image: item.cardImageMedium)
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        Task {
            if !isLoaded {
                if trending.isEmpty {
                    do {
                        let result = try await service.fetchItems(from: "trending/all/day")
                        let filtered = result.filter { $0.itemContentMedia != .person }
                        trending = filtered
                        isLoaded = true
                    } catch {
                        if Task.isCancelled { return }
                    }
                }
            }
        }
    }
}

#Preview {
    TrendingView()
}
