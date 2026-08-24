//
//  EmptyListView.swift
//  Cronica Watch App
//
//  Created by Alexandre Madeira on 21/04/23.
//

import SwiftUI

struct EmptyListView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Your Watchlist Is Empty", systemImage: "rectangle.stack.badge.plus")
        } description: {
            Text("Add titles on iPhone, then they appear here.")
        }
        .padding()
    }
}

#Preview {
    EmptyListView()
}
