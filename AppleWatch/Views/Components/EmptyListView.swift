//
//  EmptyListView.swift
//  Cronica Watch App
//
//  Created by Alexandre Madeira on 21/04/23.
//

import SwiftUI

struct EmptyListView: View {
    var body: some View {
        ContentUnavailableView("Your list is empty.", systemImage: "rectangle.on.rectangle")
            .padding(CronicaDesign.Spacing.md)
    }
}

#Preview {
    EmptyListView()
}
