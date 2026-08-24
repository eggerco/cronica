//
//  CompanyDetails.swift
//  Cronica
//
//  Created by Alexandre Madeira on 05/02/23.
//

import SwiftUI

struct CompanyDetails: View {
    let company: ProductionCompany
    @State private var showPopup = false
    @State private var popupType: ActionPopupItems?
    @StateObject private var settings = SettingsStore.shared
    @State private var page = 1
    @State private var items = [ItemContent]()
    @State private var startPagination = false
    @State private var endPagination = false
    @State private var isLoaded = false
    private let network = NetworkService.shared
    var body: some View {
        VStack {
#if os(tvOS)
            ScrollView {
                HStack {
                    Text(company.name)
                        .font(.title)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                posterStyle
            }
#else
            switch settings.sectionStyleType {
            case .list: listStyle
            case .poster: ScrollView { posterStyle }
            case .card: ScrollView { cardStyle }
            }
#endif
        }
        .cronicaLoadingOverlay(!isLoaded)
        .scrollBounceBehavior(.basedOnSize)
        .redacted(reason: isLoaded ? [] : .placeholder)
#if !os(tvOS)
        .navigationTitle(company.name)
#endif
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
        .onAppear {
            Task {
                await load()
            }
        }
        .toolbar {
#if os(iOS) || os(macOS)
            if let url = URL(string: "https://www.themoviedb.org/company/\(company.id)/") {
                ShareLink(item: url)
            }
#endif
        }
        .actionPopup(isShowing: $showPopup, for: popupType)
    }
    
    private var listStyle: some View {
        Form {
            Section {
                List {
                    if !items.isEmpty {
                        ForEach(items) { item in
                            ItemContentRowView(item: item, showPopup: $showPopup, popupType: $popupType)
                        }
                        if isLoaded && !endPagination {
                            PaginationFooter(label: "Loading") {
                                Task { await load() }
                            }
                        }
                    } else if items.isEmpty, isLoaded {
                        ContentUnavailableView("Try again later", systemImage: "popcorn")
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
            if !items.isEmpty {
                ForEach(items) { item in
                    ItemContentCardView(item: item, showPopup: $showPopup, popupType: $popupType)
                        .buttonStyle(.plain)
                }
                if isLoaded && !endPagination {
                    PaginationFooter {
                        Task { await load() }
                    }
                }
            } else {
                if isLoaded {
                    SimpleUnavailableView()
                }
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private var posterStyle: some View {
        LazyVGrid(columns: settings.isCompactUI ? DrawingConstants.compactColumns : DrawingConstants.posterColumns,
                  spacing: settings.isCompactUI ? 10 : DrawingConstants.posterSpacing) {
            if !items.isEmpty {
                ForEach(items) { item in
                    ItemContentPosterView(item: item, showPopup: $showPopup, popupType: $popupType)
                        .buttonStyle(.plain)
                }
                if isLoaded && !endPagination {
                    PaginationFooter {
                        Task { await load() }
                    }
                }
            } else {
                if isLoaded {
                    SimpleUnavailableView()
                }
            }
        }.padding(.all, settings.isCompactUI ? 10 : nil)
    }
}

#Preview {
    CompanyDetails(company: .init(name: "PlayStation Productions",
                                  id: 125281, logoPath: nil, originCountry: nil, description: nil))
}

private struct DrawingConstants {
#if os(macOS) || os(tvOS) || os(visionOS)
    static let columns: [GridItem] = [GridItem(.adaptive(minimum: 240))]
#else
    static let columns: [GridItem] = [GridItem(.adaptive(minimum: UIDevice.isIPad ? 240 : 160 ))]
#endif
    static let compactColumns: [GridItem] = [GridItem(.adaptive(minimum: 80))]
#if os(tvOS)
    static let posterColumns = [GridItem(.adaptive(minimum: 260))]
    static let posterSpacing: CGFloat = 40
#else
    static let posterColumns = [GridItem(.adaptive(minimum: 160))]
    static let posterSpacing: CGFloat = 20
#endif
}

private extension CompanyDetails {
    @MainActor
    func load() async {
        let id = company.id
        do {
            let movies = try await network.fetchCompanyFilmography(type: .movie,
                                                                   page: page,
                                                                   company: id)
            let shows = try await network.fetchCompanyFilmography(type: .tvShow,
                                                                  page: page,
                                                                  company: id)
            let result = movies + shows
            if result.isEmpty {
                endPagination = true
                return
            } else {
                page += 1
            }
            items.append(contentsOf: result.sorted { $0.itemPopularity > $1.itemPopularity })
            if !startPagination { startPagination = true }
            if !isLoaded {
                await MainActor.run {
                    self.isLoaded = true
                }
            }
        } catch {
            if Task.isCancelled { return }
            let message = "Company ID: \(id), error: \(error.localizedDescription)"
            CronicaTelemetry.shared.handleMessage(message, for: "CompanyDetails.load()")
        }
    }
}

#Preview {
    CompanyDetails(company: .init(name: "PlayStation Productions",
                                  id: 125281, logoPath: nil, originCountry: nil, description: nil))
}