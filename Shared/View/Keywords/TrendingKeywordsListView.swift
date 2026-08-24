//
//  TrendingKeywordsListView.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 10/08/23.
//

import SwiftUI
import NukeUI

struct TrendingKeywordsListView: View {
    @State private var trendingKeywords = [CombinedKeywords]()
    @State private var isLoading = true
    private let keywords: [CombinedKeywords] = [
        .init(id: 210024, name: String(localized: "Anime"), image: nil),
        .init(id: 41645, name: String(localized: "Based on Video-Game"), image: nil),
        .init(id: 9715, name: String(localized: "Superhero"), image: nil),
        .init(id: 9799, name: String(localized: "Romantic Comedy"), image: nil),
        .init(id: 9672, name: String(localized: "Based on true story"), image: nil),
        .init(id: 256183, name: String(localized: "Supernatural Horror"), image: nil),
        .init(id: 10349, name: String(localized: "Survival"), image: nil),
        .init(id: 9882, name: String(localized: "Space"), image: nil),
        .init(id: 818, name: String(localized: "Based on novel or book"), image: nil),
        .init(id: 9951, name: String(localized: "Alien"), image: nil),
        .init(id: 189402, name: String(localized: "Crime Investigation"), image: nil)
    ]
    private var service: NetworkService = NetworkService.shared
    var body: some View {
        Section {
            ScrollView {
#if os(tvOS)
                HStack {
                    Text("Browse by Themes")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                    Spacer()
                }
                .padding(.horizontal, 64)
#endif
                LazyVGrid(columns: DrawingConstants.columns, spacing: 20) {
                    ForEach(trendingKeywords) { keyword in
                        if keyword.image != nil {
                            TrendingCardView(keyword: keyword, isLoading: $isLoading)
#if os(tvOS)
                                .padding(.vertical)
#endif
                        }
                    }
                }
                .padding([.horizontal, .bottom])
            }
            .task {
                await load()
            }
            .scrollBounceBehavior(.basedOnSize)
#if os(iOS)
            .redacted(reason: isLoading ? .placeholder : [])
#elseif os(tvOS)
            .ignoresSafeArea(.all, edges: .horizontal)
#endif
        } header: {
#if !os(tvOS)
            HStack {
                Text("Browse by Themes")
                    .font(.title3)
                    .fontWeight(.medium)
                    .padding(.horizontal)
                Spacer()
            }
#endif
        }
    }
    
    private func load() async {
        if trendingKeywords.isEmpty {
            for item in keywords.sorted(by: { $0.name < $1.name}) {
                let itemFromKeyword = try? await service.fetchKeyword(type: .movie,
                                                                      page: 1,
                                                                      keywords: item.id,
                                                                      sortBy: TMDBSortBy.popularity.rawValue)
                var url: URL?
                if let firstItem = itemFromKeyword?.first {
                    url = firstItem.cardImageMedium
                }
                let content: CombinedKeywords = .init(id: item.id, name: item.name, image: url)
                trendingKeywords.append(content)
            }
            await MainActor.run {
                withAnimation {
                    self.isLoading = false
                }
            }
        }
    }
}

#Preview {
    TrendingKeywordsListView()
}

struct CombinedKeywords: Identifiable, Hashable {
    let id: Int
    let name: String
    let image: URL?
}

private struct TrendingCardView: View {
    let keyword: CombinedKeywords
    @Binding var isLoading: Bool
    var body: some View {
        NavigationLink(value: keyword) {
            LazyImage(url: keyword.image) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    ZStack {
                        Rectangle().fill(.gray.gradient)
                    }
                }
            }
            .overlay {
                ZStack {
                    Rectangle().fill(.black.opacity(0.5))
                    VStack {
                        Spacer()
                        HStack {
                            Text(keyword.name)
                                .foregroundColor(.white)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.leading)
                                .lineLimit(3)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                }
                .frame(width: DrawingConstants.width, height: DrawingConstants.height, alignment: .center)
            }
            .frame(width: DrawingConstants.width, height: DrawingConstants.height, alignment: .center)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 2.5, x: 0, y: 2.5)
            .buttonStyle(.plain)
        }
#if os(iOS)
        .disabled(isLoading)
#elseif os(tvOS)
        .buttonStyle(.card)
#elseif os(macOS)
        .buttonStyle(.plain)
#endif
        .frame(width: DrawingConstants.width, height: DrawingConstants.height, alignment: .center)
    }
}

private struct DrawingConstants {
#if os(iOS)
    static let columns = [GridItem(.adaptive(minimum: 160))]
    static let width: CGFloat = 160
    static let height: CGFloat = 100
#elseif os(tvOS)
    static let columns = [GridItem(.adaptive(minimum: 400))]
    static let width: CGFloat = 400
    static let height: CGFloat = 240
#else
    static let columns = [GridItem(.adaptive(minimum: 240))]
    static let width: CGFloat = 240
    static let height: CGFloat = 140
#endif
}
