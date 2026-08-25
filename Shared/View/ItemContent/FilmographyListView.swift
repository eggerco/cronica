//
//  FilmographyListView.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 13/07/22.
//

import SwiftUI

struct FilmographyListView: View {
    let filmography: [ItemContent]?
    @Binding var showPopup: Bool
    @Binding var popupType: ActionPopupItems?
    @StateObject private var settings = SettingsStore.shared
#if !os(watchOS)
    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: DrawingConstants.posterColumns))
    ]
    private let cardColumns: [GridItem] = [
        GridItem(.adaptive(minimum: DrawingConstants.columns))
    ]
#endif
    var body: some View {
        if let filmography {
            if !filmography.isEmpty {
#if os(watchOS)
                VStack {
                    TitleView(title: String(localized: "Filmography"))
                    LazyVStack {
                        ForEach(filmography) { item in
                            NavigationLink(value: item) {
                                ItemContentRow(item: item)
                            }
                        }
                    }
                }
#else
                VStack {
#if os(tvOS)
                    cardStyle
#else
                    switch settings.listsDisplayType {
                    case .standard: cardStyle
                    case .poster: posterStyle
                    case .card: cardStyle
                    }
#endif
                }
#endif
            }
        }
    }
    
#if !os(watchOS)
    @ViewBuilder
    private var posterStyle: some View {
        if let filmography {
            LazyVGrid(columns: settings.isCompactUI ? DrawingConstants.compactPosterColumns : columns,
                      spacing: settings.isCompactUI ? 10 : 20) {
                ForEach(filmography) { item in
                    ItemContentPosterView(item: item,
                                          showPopup: $showPopup,
                                          popupType: $popupType)
                }
            }.padding(.all, settings.isCompactUI ? 10 : nil)
        }
    }
    
    @ViewBuilder
    private var cardStyle: some View {
        if let filmography {
            LazyVGrid(columns: cardColumns, spacing: 20) {
                ForEach(filmography) { item in
                    ItemContentCardView(item: item,
                                        showPopup: $showPopup,
                                        popupType: $popupType)
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
#endif
}

#Preview {
    FilmographyListView(filmography: ItemContent.examples,
                        showPopup: .constant(false),
                        popupType: .constant(nil))
}

private struct DrawingConstants {
#if os(macOS) || os(visionOS)
    static let posterColumns: CGFloat = 160
    static let columns: CGFloat = 240
    static let spacing: CGFloat = 20
#elseif os(tvOS)
    static let posterColumns: CGFloat = 260
    static let columns: CGFloat = 420
    static let spacing: CGFloat = 40
#elseif os(iOS)
    static let posterColumns: CGFloat = 160
    static let spacing: CGFloat = 20
    static let columns: CGFloat = 160
#endif
    static let compactPosterColumns = [GridItem(.adaptive(minimum: 80))]
    static let compactSpacing: CGFloat = 10
}
