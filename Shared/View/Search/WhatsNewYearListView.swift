//
//  WhatsNewYearListView.swift
//  Cronica
//

import SwiftUI

/// Curated Discover row for popular titles from the current calendar year.
struct WhatsNewYearListView: View {
    @State private var items = [ItemContent]()
    @State private var isLoading = true
    @State private var showPopup = false
    @State private var popupType: ActionPopupItems?
    private let year = Calendar.current.component(.year, from: Date())
    private let service = NetworkService.shared

    var body: some View {
        Group {
            if !items.isEmpty {
                HorizontalItemContentListView(
                    items: items,
                    title: String(format: String(localized: "What's New in %lld"), Int64(year)),
                    subtitle: String(localized: "Popular this year"),
                    showPopup: $showPopup,
                    popupType: $popupType,
                    displayAsCard: true
                )
                .redacted(reason: isLoading ? .placeholder : [])
            }
        }
        .task { await load() }
        .actionPopup(isShowing: $showPopup, for: popupType)
    }

    private func load() async {
        guard items.isEmpty else { return }
        let yearString = String(year)
        async let movies = try? service.fetchYearContent(year: yearString, type: .movie)
        async let shows = try? service.fetchYearContent(year: yearString, type: .tvShow)
        let movieResults = await movies ?? []
        let showResults = await shows ?? []
        let combined = (movieResults + showResults)
            .filter { $0.posterPath != nil || $0.backdropPath != nil }
            .sorted { $0.itemPopularity > $1.itemPopularity }
        await MainActor.run {
            withAnimation {
                items = Array(combined.prefix(20))
                isLoading = false
            }
        }
    }
}

#Preview {
    ScrollView {
        WhatsNewYearListView()
    }
}
