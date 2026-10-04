//
//  WatchlistCardSection.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 20/12/22.
//

import SwiftUI

struct WatchlistCardSection: View {
    private let context = PersistenceController.shared
    let items: [WatchlistItem]
    let title: String
    var emptyFilter: SmartFiltersTypes? = nil
    @StateObject private var settings = SettingsStore.shared
    @Binding var showPopup: Bool
    @Binding var popupType: ActionPopupItems?
    var body: some View {
        if !items.isEmpty { 
            ScrollView {
                LazyVGrid(columns: columns,
                          spacing: DrawingConstants.spacing) {
#if os(tvOS)
                    Section {
                        ForEach(items, id: \.itemContentID) { item in
                            WatchlistItemCardView(content: item, showPopup: $showPopup, popupType: $popupType)
                        }
                    } 
#else
                    Section {
                        ForEach(items, id: \.itemContentID) { item in
                            WatchlistItemCardView(content: item, showPopup: $showPopup, popupType: $popupType,
                                                  fillsColumn: fixedColumnCount != nil)
                                .buttonStyle(.plain)
                        }
                        .onDelete(perform: delete)
                    } header: {
                        HStack(alignment: .firstTextBaseline) {
                            Text(title)
                                .foregroundColor(.secondary)
                                .font(.footnote)
                            Spacer()
                            Text("\(items.count) items")
                                .foregroundColor(.secondary)
                                .font(.footnote)
                        }
                        .padding(.horizontal)
                    }
#endif
                }.padding()
            }
        } else {
            EmptyListView(filter: emptyFilter)
        }
    }
    
    /// User-chosen column count, or nil to keep the adaptive layout.
    private var fixedColumnCount: Int? {
#if os(tvOS)
        nil
#else
        settings.watchlistCardColumns > 0 ? settings.watchlistCardColumns : nil
#endif
    }

    private var columns: [GridItem] {
        if let count = fixedColumnCount {
            return Array(repeating: GridItem(.flexible(), spacing: DrawingConstants.spacing), count: count)
        }
        return [GridItem(.adaptive(minimum: DrawingConstants.columns))]
    }

    private func delete(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(context.delete)
        }
    }
}

#Preview {
    WatchlistCardSection(items: [.example], title: "Preview", showPopup: .constant(false), popupType: .constant(nil))
}

private struct DrawingConstants {
#if os(macOS)
    static let columns: CGFloat = 240
    static let spacing: CGFloat = 20
#elseif os(tvOS)
    static let columns: CGFloat = 420
    static let spacing: CGFloat = 40
#elseif os(iOS)
    static let columns: CGFloat = 160
    static let spacing: CGFloat = 20
#elseif os(visionOS)
    static let columns: CGFloat = 240
    static let spacing: CGFloat = 20
#endif
}
