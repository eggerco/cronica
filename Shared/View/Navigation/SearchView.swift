//
//  SearchView.swift
//  Cronica
//
//  Created by Alexandre Madeira on 02/03/22.
//

import SwiftUI
#if os(iOS)
import AdmobSwiftUI
#endif

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
#if os(iOS)
    @StateObject private var nativeViewModel = NativeAdViewModel(
        adUnitID: AdConfiguration.AdUnitID.native,
        requestInterval: AdConfiguration.nativeRefreshInterval
    )
#endif
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
        .navigationDestination(for: Person.self) { person in
            PersonDetailsView(name: person.name, id: person.id)
#if os(tvOS)
                .ignoresSafeArea(.all, edges: .horizontal)
#endif
        }
        .navigationDestination(for: ItemContent.self) { item in
            ItemContentDetails(title: item.itemTitle, id: item.id, type: item.itemContentMedia)
#if os(tvOS)
                .ignoresSafeArea(.all, edges: .horizontal)
#endif
        }
        .navigationDestination(for: ProductionCompany.self) { item in
            CompanyDetails(company: item)
        }
        .navigationDestination(for: [ProductionCompany].self) { item in
            CompaniesListView(companies: item)
        }
        .navigationDestination(for: SearchItemContent.self) { item in
            if item.media == .person {
                PersonDetailsView(name: item.itemTitle, id: item.id)
#if os(tvOS)
                .ignoresSafeArea(.all, edges: .horizontal)
#endif
            } else {
                ItemContentDetails(title: item.itemTitle, id: item.id, type: item.media)
#if os(tvOS)
                .ignoresSafeArea(.all, edges: .horizontal)
#endif
            }
        }
        .navigationDestination(for: [String:[ItemContent]].self) { item in
            let title = item.map { (key, _) in key }.first
            let items = item.map { (_, value) in value }.first
            if let title, let items {
                ItemContentSectionDetails(title: title, items: items)
            }
        }
        .navigationDestination(for: [Person].self) { items in
            DetailedPeopleList(items: items)
        }
        .navigationDestination(for: CombinedKeywords.self) { keyword in
            KeywordSectionView(keyword: keyword)
#if os(tvOS)
                .ignoresSafeArea(.all, edges: .horizontal)
#endif
        }
#if os(iOS) || os(visionOS)
        .searchable(text: $viewModel.query,
                    isPresented: $shouldFocusOnSearchField,
                    placement: UIDevice.isIPad ? .toolbar : .navigationBarDrawer(displayMode: .always),
                    prompt: Text("Movies, Shows, People"))
        .searchScopes($scope) {
            ForEach(SearchItemsScope.allCases) { scope in
                Text(scope.localizableTitle).tag(scope)
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
                    searchNativeAdRow(resultCount: viewModel.items.count)
                    if !viewModel.items.isEmpty {
                        loadableProgressRing
                    }
                case .movies:
                    let items = viewModel.items.filter { $0.itemContentMedia == .movie }
                    ForEach(items) { item in
                        SearchItemView(item: item,
                                       showPopup: $showPopup,
                                       popupType: $popupType)
                    }
                    searchNativeAdRow(resultCount: items.count)
                    loadableProgressRing
                case .shows:
                    let items = viewModel.items.filter { $0.itemContentMedia == .tvShow && $0.media != .person }
                    ForEach(items) { item in
                        SearchItemView(item: item,
                                       showPopup: $showPopup,
                                       popupType: $popupType)
                    }
                    searchNativeAdRow(resultCount: items.count)
                    loadableProgressRing
                case .people:
                    let items = viewModel.items.filter { $0.media == .person }
                    ForEach(items) { item in
                        SearchItemView(item: item,
                                       showPopup: $showPopup,
                                       popupType: $popupType)
                    }
                    searchNativeAdRow(resultCount: items.count)
                    loadableProgressRing
                }
            }
        }
    }

    @ViewBuilder
    private func searchNativeAdRow(resultCount: Int) -> some View {
#if os(iOS)
        if SearchAdPolicy.shouldShowNativeAd(
            hasPurchasedTipJar: SettingsStore.shared.hasPurchasedTipJar,
            monetizationDisabled: PreviewVideoRuntime.shouldDisableMonetization(),
            resultCount: resultCount
        ) {
            NativeAdView(nativeViewModel: nativeViewModel, style: .largeBanner)
                .frame(height: 320)
                .listRowInsets(.init(top: 12, leading: 16, bottom: 12, trailing: 16))
                .onAppear {
                    nativeViewModel.refreshAd()
                }
        }
#endif
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            viewModel.loadMoreItems()
        }
    }
}

#Preview {
    SearchView(shouldFocusOnSearchField: .constant(false))
}
