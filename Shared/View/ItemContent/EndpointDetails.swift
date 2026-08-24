//
//  EndpointDetails.swift
//  Cronica
//
//  Created by Alexandre Madeira on 26/11/22.
//

import SwiftUI

struct EndpointDetails: View {
    let title: String
    var endpoint: Endpoints?
    @StateObject private var settings = SettingsStore.shared
    @State private var showPopup = false
    @State private var popupType: ActionPopupItems?
    
    @State private var items = [ItemContent]()
    @State private var page = 1
    @State private var startPagination: Bool = false
    @State private var endPagination: Bool = false
    @State private var isLoading = true
    @State private var isLoadingMore = false
    @State private var showError = false
    var body: some View {
        VStack {
#if os(tvOS)
            cardStyle
#else
            switch settings.sectionStyleType {
            case .list: listStyle
            case .card: cardStyle
            case .poster: ScrollView { posterStyle }
            }
#endif
        }
        .cronicaLoadingOverlay(isLoading)
        .overlay {
            if !isLoading && items.isEmpty {
                ContentUnavailableView {
                    Label(showError ? "Couldn't Load" : "Nothing Here",
                          systemImage: showError ? "wifi.exclamationmark" : "popcorn")
                } description: {
                    Text(showError ? "Check your connection and try again." : "Try again later.")
                } actions: {
                    Button("Retry") {
                        showError = false
                        isLoading = true
                        Task { await loadMoreItems(for: endpoint) }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .actionPopup(isShowing: $showPopup, for: popupType)
        .task {
            await loadMoreItems(for: endpoint)
        }
        .navigationTitle(title)
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
        .scrollBounceBehavior(.basedOnSize)
    }
    
    private var listStyle: some View {
        Form {
            Section {
                List {
                    ForEach(items) { item in
                        ItemContentRowView(item: item, showPopup: $showPopup, popupType: $popupType)
                    }
                    if endpoint != nil && !endPagination && !isLoading {
                        PaginationFooter(label: "Loading", isLoadingMore: isLoadingMore) {
                            Task { await loadMoreItems(for: endpoint) }
                        }
                    }
                }
            }
        }
    }
    
    private var cardStyle: some View {
        ScrollView {
            LazyVGrid(columns: DrawingConstants.cardColumns, spacing: 20) {
                ForEach(items) { item in
                    ItemContentCardView(item: item, showPopup: $showPopup, popupType: $popupType)
                        .buttonStyle(.plain)
                }
                if endpoint != nil && !endPagination && !isLoading {
                    PaginationFooter(isLoadingMore: isLoadingMore) {
                        Task { await loadMoreItems(for: endpoint) }
                    }
                }
            }
            .padding()
        }
    }
    
    private var posterStyle: some View {
        LazyVGrid(columns: settings.isCompactUI ? DrawingConstants.compactColumns : DrawingConstants.posterColumns,
                  spacing: settings.isCompactUI ? 10 : 20) {
            ForEach(items) { item in
                ItemContentPosterView(item: item, showPopup: $showPopup, popupType: $popupType)
                    .buttonStyle(.plain)
            }
            if endpoint != nil && !endPagination && !isLoading {
                PaginationFooter(isLoadingMore: isLoadingMore) {
                    Task { await loadMoreItems(for: endpoint) }
                }
            }
        }
#if os(iOS)
                  .padding(.all, settings.isCompactUI ? 10 : nil)
#else
                  .padding()
#endif
    }
}

#Preview {
    EndpointDetails(title: "Preview", endpoint: .nowPlaying)
}

private struct DrawingConstants {
#if os(iOS)
    static let cardColumns = [GridItem(.adaptive(minimum: 160))]
    static let posterColumns = [GridItem(.adaptive(minimum: 160))]
#else
    static let cardColumns = [GridItem(.adaptive(minimum: 240))]
    static let posterColumns = [GridItem(.adaptive(minimum: 160))]
#endif
    static let compactColumns = [GridItem(.adaptive(minimum: 80))]
}

extension EndpointDetails {
    private func loadMoreItems(for endpoint: Endpoints?) async {
        guard let endpoint else { return }
        guard !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let result = try await NetworkService.shared.fetchItems(from: "\(endpoint.type.rawValue)/\(endpoint.rawValue)", page: String(page))
            let filtered = result.filter { $0.backdropPath != nil && $0.posterPath != nil }
            for item in filtered {
                if !items.contains(item) {
                    items.append(item)
                }
            }
            if !items.isEmpty {
                page += 1
                startPagination = false
            }
            if result.isEmpty { endPagination = true }
            showError = false
            withAnimation { isLoading = false }
        } catch {
            if Task.isCancelled { return }
            showError = items.isEmpty
            withAnimation { isLoading = false }
        }
    }
}
