//
//  SearchView.swift
//  Cronica
//
//  Created by Alexandre Madeira on 02/03/22.
//

import SwiftUI

struct SearchView: View {
    static let tag: Screens? = .search
#if os(tvOS)
    private let columns: [GridItem] = [GridItem(.adaptive(minimum: 260))]
#else
    private let columns: [GridItem] = [GridItem(.adaptive(minimum: 160))]
#endif
    @StateObject private var viewModel = SearchViewModel()
    @State private var showPopup = false
    @State private var popupType: ActionPopupItems?
    @State private var scope: SearchItemsScope = .noScope
    @State private var currentlyQuery = String()
    @Binding var shouldFocusOnSearchField: Bool
    var body: some View {
        VStack {
#if os(iOS)
            listView
#elseif os(tvOS) || os(macOS) || os(visionOS)
            posterView
#endif
        }
        .task {
            if !viewModel.items.isEmpty, viewModel.query.isEmpty {
                viewModel.items.removeAll()
            }
        }
#if !os(tvOS)
        .navigationTitle("Search")
#endif
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
        .cronicaSearchNavigationDestinations()
#if os(iOS) || os(visionOS)
        .searchable(text: $viewModel.query,
                    isPresented: $shouldFocusOnSearchField,
                    placement: UIDevice.isIPad ? .toolbar : .navigationBarDrawer(displayMode: .always),
                    prompt: Text("Movies, Shows, People"))
        .safeAreaInset(edge: .top, spacing: 0) {
            if !viewModel.query.isEmpty {
                searchScopePicker
            }
        }
#elseif os(tvOS)
        .searchable(text: $viewModel.query, prompt: "Movies, Shows, People")
#elseif os(macOS)
        .searchable(text: $viewModel.query, placement: .toolbar, prompt: "Movies, Shows, People")
#endif
        .disableAutocorrection(true)
        .task(id: viewModel.query) {
            if currentlyQuery != viewModel.query {
                currentlyQuery = viewModel.query
                await viewModel.search(viewModel.query)
            }
        }
        .actionPopup(isShowing: $showPopup, for: popupType)
#if os(tvOS)
        .ignoresSafeArea(.all, edges: .horizontal)
#endif
    }

#if os(iOS) || os(visionOS)
    private var searchScopePicker: some View {
        Picker("Filter", selection: $scope) {
            ForEach(SearchItemsScope.allCases) { item in
                Text(item.localizableTitle).tag(item)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .padding(.horizontal)
        .padding(.vertical, 8)
        .sensoryFeedback(.selection, trigger: scope)
    }
#endif
    
#if os(iOS) || os(macOS) || os(visionOS)
    @ViewBuilder
    private var listView: some View {
        switch viewModel.stage {
        case .none:
            ScrollView {
                VStack {
                    TrendingKeywordsListView()
                        .environmentObject(viewModel)
                    Spacer()
                }
            }
        case .searching: searchingView
        case .empty: emptyView
        case .failure: failureView
        case .success:
            List {
                switch scope {
                case .noScope:
                    ForEach(viewModel.items) { item in
                        SearchItemView(item: item,
                                       showPopup: $showPopup,
                                       popupType: $popupType)
                    }
                    if !viewModel.items.isEmpty {
                        loadableProgressRing
                    }
                case .movies:
                    ForEach(viewModel.items.filter { $0.itemContentMedia == .movie }) { item in
                        SearchItemView(item: item,
                                       showPopup: $showPopup,
                                       popupType: $popupType)
                    }
                    loadableProgressRing
                case .shows:
                    ForEach(viewModel.items.filter { $0.itemContentMedia == .tvShow && $0.media != .person }) { item in
                        SearchItemView(item: item,
                                       showPopup: $showPopup,
                                       popupType: $popupType)
                    }
                    loadableProgressRing
                case .people:
                    ForEach(viewModel.items.filter { $0.media == .person }) { item in
                        SearchItemView(item: item,
                                       showPopup: $showPopup,
                                       popupType: $popupType)
                    }
                    loadableProgressRing
                }
            }
        }
    }
#endif
    
#if os(tvOS) || os(macOS) || os(visionOS)
    @ViewBuilder
    private var posterView: some View {
        switch viewModel.stage {
        case .none: TrendingKeywordsListView()
        case .searching: searchingView
        case .empty: emptyView
        case .failure: failureView
        case .success:
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(viewModel.items) { item in
                        if item.media == .person {
                            PersonSearchImage(item: item)
#if os(tvOS)
                                .padding()
#endif
                        } else {
                            SearchContentPosterView(item: item,
                                                    showPopup: $showPopup,
                                                    popupType: $popupType)
#if os(tvOS)
                            .padding()
#endif
                        }
                    }
                    .buttonStyle(.plain)
                    if viewModel.startPagination && !viewModel.endPagination {
                        CenterHorizontalView {
                            ProgressView()
                                .padding()
                                .onAppear(perform: loadMoreOnAppear)
                        }
                    }
                }
#if !os(tvOS)
                .padding()
#endif
            }
#if os(tvOS)
            .ignoresSafeArea(.all, edges: .horizontal)
#endif
        }
    }
#endif
    
    @ViewBuilder
    private var emptyView: some View {
        ContentUnavailableView.search(text: viewModel.query)
    }
    
    private var searchingView: some View {
        ProgressView("Searching")
            .foregroundColor(.secondary)
            .padding()
    }
    
    @ViewBuilder
    private var failureView: some View {
        ContentUnavailableView("Try again later", systemImage: "magnifyingglass").padding()
    }
    
    @ViewBuilder
    private var loadableProgressRing: some View {
        if viewModel.startPagination && !viewModel.endPagination {
            CenterHorizontalView {
                ProgressView()
                    .padding()
                    .onAppear(perform: loadMoreOnAppear)
            }
        }
    }
}

extension SearchView {
    private func loadMoreOnAppear() {
        viewModel.loadMoreItems()
    }
}

#Preview {
    SearchView(shouldFocusOnSearchField: .constant(false))
}
