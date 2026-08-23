//
//  SearchViewModel.swift
//  Cronica
//
//  Created by Alexandre Madeira on 06/03/22.
//

import Foundation
import SwiftUI

@MainActor final class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    private var service: NetworkService = NetworkService.shared
    var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var page = 1
    @Published var items = [SearchItemContent]()
    @Published var startPagination: Bool = false
    @Published var endPagination: Bool = false
    @Published var stage: SearchStage = .none
    
    func search(_ query: String) async {
        if Task.isCancelled { return }
        if query.isEmpty {
            startPagination = false
            withAnimation {
                items.removeAll()
                stage = .none
            }
            return
        }
        withAnimation { stage = .searching }
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }
        do {
            if Task.isCancelled {
                withAnimation { stage = .none }
                return
            }
            try await Task.sleep(nanoseconds: 300_000_000)
            if !items.isEmpty {
                items.removeAll()
            }
            // restart pagination values
            page = 1
            endPagination = false
            let result = try await service.search(query: trimmedQuery, page: "1")
            page += 1
            if SettingsStore.shared.disableSearchFilter {
                items.append(contentsOf: result.sorted(by: { $0.itemPopularity > $1.itemPopularity }))
            } else {
                let filtered = await filter(for: result)
                items.append(contentsOf: filtered.sorted(by: { $0.itemPopularity > $1.itemPopularity }))
            }
            if self.items.isEmpty {
                withAnimation { stage = .empty }
                return
            }
            withAnimation {  stage = .success }
            startPagination = true
        } catch {
            if query.isEmpty, !items.isEmpty { items.removeAll() }
            if Task.isCancelled { return }
            withAnimation { stage = .failure }
            CronicaTelemetry.shared.handleMessage(error.localizedDescription,
                                                  for: "SearchViewModel.search()")
        }
    }
    
    func loadMoreItems() {
        if Task.isCancelled { return }
        if items.isEmpty { return }
        if endPagination { return }
        if Task.isCancelled { return }
        Task {
            let result = try? await service.search(query: trimmedQuery, page: "\(page)")
            guard let result else { return }
            if result.isEmpty { endPagination.toggle() }
            let filtered = await filter(for: result)
            withAnimation {
                self.items.append(contentsOf: filtered.sorted(by: { $0.itemPopularity > $1.itemPopularity }))
            }
            self.page += 1
        }
    }
	
    private func filter(for items: [SearchItemContent]) async -> [SearchItemContent] {
        var result = [SearchItemContent]()
        for item in items {
            let contentKeywords = try? await service.fetchKeywords(type: item.itemContentMedia, id: item.id)
            if let contentKeywords {
                var keywordsArray = [Int]()
                let _: [()] = contentKeywords.map { item in
                    keywordsArray.append(item.id)
                }
                let containsNSFW = !Set(keywordsArray).isDisjoint(with: nsfwKeywords)
                if !containsNSFW {
                    result.append(item)
                }
            } else {
                result.append(item)
            }
        }
        return result
    }
}

