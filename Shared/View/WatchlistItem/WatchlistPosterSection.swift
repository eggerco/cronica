//
//  WatchlistPosterSection.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 20/12/22.
//

import SwiftUI

struct WatchlistPosterSection: View {
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
                LazyVGrid(columns: settings.isCompactUI ? DrawingConstants.compactColumns : DrawingConstants.posterColumns,
                          spacing: settings.isCompactUI ? 10 : 20) {
                    Section {
                        ForEach(items, id: \.itemContentID) { item in
                            WatchlistItemPosterView(content: item, showPopup: $showPopup, popupType: $popupType)
                                .buttonStyle(.plain)
#if os(tvOS)
                                .padding(.vertical)
#endif
                        }
                        .onDelete(perform: delete)
                    } header: {
#if !os(tvOS)
                        HStack(alignment: .firstTextBaseline) {
                            Text(NSLocalizedString(title, comment: ""))
                                .foregroundColor(.secondary)
                                .font(.footnote)
                            Spacer()
                            Text("\(items.count) items")
                                .foregroundColor(.secondary)
                                .font(.footnote)
                        }
                        .padding(.horizontal)
#endif
                    }
                }.padding(.all, settings.isCompactUI ? 10 : nil)
            }
        } else {
            EmptyListView(filter: emptyFilter)
        }
    }
    
    private func delete(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(context.delete)
        }
    }
}

#Preview {
    WatchlistPosterSection(items: [.example], title: "Preview", showPopup: .constant(false), popupType: .constant(nil))
}

private struct DrawingConstants {
#if os(macOS)
    static let posterColumns = [GridItem(.adaptive(minimum: 160))]
    static let columns = [GridItem(.adaptive(minimum: 240))]
#elseif os(tvOS)
    static let posterColumns = [GridItem(.adaptive(minimum: 260))]
    static let columns = [GridItem(.adaptive(minimum: 380))]
#else
    static let posterColumns = [GridItem(.adaptive(minimum: 160))]
    static let columns  = [GridItem(.adaptive(minimum: 160))]
    static let spacing: CGFloat = 20
#endif
    static let compactColumns = [GridItem(.adaptive(minimum: 80))]
}
