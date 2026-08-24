//
//  KeywordSectionView.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 10/08/23.
//

import SwiftUI

struct KeywordSectionView: View {
    let keyword: CombinedKeywords
    // States
    @StateObject private var settings = SettingsStore.shared
    @State private var showPopup = false
    @State private var popupType: ActionPopupItems?
    @State private var sortBy: TMDBSortBy = .popularity
    @State private var page = 1
    @State private var items = [ItemContent]()
    @State private var isLoaded = false
    @State private var isLoadingMore = false
    @State private var startPagination = false
    @State private var endPagination = false
    @State private var showError = false
    // Network service
    private let network = NetworkService.shared
    var body: some View {
        VStack {
#if os(tvOS)
            ScrollView {
                HStack {
                    Text(keyword.name)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Spacer()
                    sortButton
                }
                .padding(.horizontal, 64)
                cardStyle
            }
#else
            switch settings.sectionStyleType {
            case .list: listStyle
            case .poster: ScrollView { posterStyle }
            case .card: ScrollView { cardStyle }
            }
#endif
        }
#if !os(tvOS)
        .navigationTitle(keyword.name)
#endif
        .overlay {
            if !isLoaded {
                ProgressView().unredacted()
            } else if items.isEmpty {
                ContentUnavailableView {
                    Label(showError ? "Couldn't Load" : "Nothing Here",
                          systemImage: showError ? "wifi.exclamationmark" : "popcorn")
                } description: {
                    Text(showError ? "Check your connection and try again." : "Try again later.")
                } actions: {
                    Button("Retry") {
                        showError = false
                        isLoaded = false
                        page = 1
                        endPagination = false
                        Task { await load(keyword.id, sortBy: sortBy, reload: true) }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .onAppear {
            Task {
                await load(keyword.id, sortBy: sortBy, reload: false)
            }
        }
        .onChange(of: sortBy) { _, newSortBy in
            Task {
                await load(keyword.id, sortBy: sortBy, reload: true)
            }
        }
        .toolbar {
#if os(iOS)
            ToolbarItem(placement: .topBarTrailing) {
                sortButton
                    .unredacted()
                    .disabled(!isLoaded)
            }
#elseif os(macOS) || os(visionOS)
            ToolbarItem {
                sortButton
                    .unredacted()
                    .disabled(!isLoaded)
            }
#endif
        }
        .redacted(reason: isLoaded ? [] : .placeholder)
#if os(tvOS)
        .ignoresSafeArea(.all, edges: .horizontal)
#endif
    }
    
    private var sortButton: some View {
        Menu {
            Picker("Sort Order", selection: $sortBy) {
                ForEach(TMDBSortBy.allCases) { item in
                    Text(item.localizedString).tag(item)
                }
            }
            .pickerStyle(.inline)
        } label: {
            Label("Sort By",
                  systemImage: "arrow.up.arrow.down.circle")
        }
        .labelStyle(.iconOnly)
    }
    
    private var listStyle: some View {
        Form {
            Section {
                List {
                    ForEach(items) { item in
                        ItemContentRowView(item: item, showPopup: $showPopup, popupType: $popupType)
                    }
                    if isLoaded && !endPagination {
                        CenterHorizontalView {
                            ProgressView("Loading")
                                .padding(.horizontal)
                                .onAppear(perform: loadMoreOnAppear)
                        }
                    }
                }
            }
        }
#if os(macOS)
        .formStyle(.grouped)
#endif
    }
    
    private var cardStyle: some View {
        LazyVGrid(columns: DrawingConstants.columns, spacing: 20) {
            ForEach(items) { item in
                ItemContentCardView(item: item, showPopup: $showPopup, popupType: $popupType)
                    .buttonStyle(.plain)
#if os(tvOS)
                    .padding(.vertical)
#endif
            }
            if isLoaded && !endPagination {
                CenterHorizontalView {
                    ProgressView()
                        .padding()
                        .onAppear(perform: loadMoreOnAppear)
                }
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private var posterStyle: some View {
        LazyVGrid(columns: settings.isCompactUI ? DrawingConstants.compactColumns : DrawingConstants.posterColumns,
                  spacing: settings.isCompactUI ? 10 : 20) {
            ForEach(items) { item in
                ItemContentPosterView(item: item, showPopup: $showPopup, popupType: $popupType)
                    .buttonStyle(.plain)
            }
            if isLoaded && !endPagination {
                CenterHorizontalView {
                    ProgressView()
                        .padding()
                        .onAppear(perform: loadMoreOnAppear)
                }
            }
        }.padding(.all, settings.isCompactUI ? 10 : nil)
    }
}

private struct DrawingConstants {
#if os(macOS) || os(visionOS)
    static let columns: [GridItem] = [GridItem(.adaptive(minimum: 240))]
#elseif os(tvOS)
    static let columns: [GridItem] = [GridItem(.adaptive(minimum: 420))]
#else
    static let columns: [GridItem] = [GridItem(.adaptive(minimum: 160))]
#endif
    static let compactColumns: [GridItem] = [GridItem(.adaptive(minimum: 80))]
    static let posterColumns = [GridItem(.adaptive(minimum: 160))]
}

extension KeywordSectionView {
    private func loadMoreOnAppear() {
        guard !isLoadingMore else { return }
        Task {
            await load(keyword.id, sortBy: sortBy, reload: false)
        }
    }
    private func load(_ id: Int, sortBy: TMDBSortBy, reload: Bool) async {
        guard !isLoadingMore || reload else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            if reload {
                withAnimation {
                    items.removeAll()
                    isLoaded = false
                    page = 1
                    endPagination = false
                }
            }
            let movies = try await network.fetchKeyword(type: .movie,
                                                        page: page,
                                                        keywords: id,
                                                        sortBy: sortBy.rawValue)
            let shows = try await network.fetchKeyword(type: .tvShow,
                                                       page: page,
                                                       keywords: id,
                                                       sortBy: sortBy.rawValue)
            let result = movies + shows
            if result.isEmpty {
                endPagination = true
                isLoaded = true
                return
            } else {
                page += 1
            }
            withAnimation {
                items.append(contentsOf: result.sorted { $0.itemPopularity > $1.itemPopularity })
            }
            if !startPagination { startPagination = true }
            isLoaded = true
        } catch {
            if Task.isCancelled { return }
            showError = items.isEmpty
            isLoaded = true
            let message = "Keyword ID: \(id), error: \(error.localizedDescription)"
            CronicaTelemetry.shared.handleMessage(message, for: "KeywordSection.load()")
        }
    }
}
