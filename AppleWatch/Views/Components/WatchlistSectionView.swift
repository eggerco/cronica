//
//  WatchlistSectionView.swift
//  Cronica Watch App
//
//  Created by Alexandre Madeira on 21/04/23.
//

import SwiftUI

struct WatchlistSectionView: View {
    let items: [WatchlistItem]
    let title: String
    @State private var showPopup = false
    @State private var popupType: ActionPopupItems?
    var body: some View {
        if !items.isEmpty {
            Section {
                ForEach(items) { item in
                    WatchlistItemRowView(content: item, showPopup: $showPopup, popupType: $popupType)
                }
            } header: {
                Text(NSLocalizedString(title, comment: ""))
                    .font(CronicaDesign.Typography.caption())
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
            }
        } else {
            ContentUnavailableView("No results", systemImage: "rectangle.on.rectangle")
                .padding(CronicaDesign.Spacing.md)
        }
    }
}

#Preview {
    WatchlistSectionView(items: [.example], title: "SwiftUI Preview")
}
