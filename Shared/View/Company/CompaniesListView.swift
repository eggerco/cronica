//
//  CompaniesListView.swift
//  Cronica
//
//  Created by Alexandre Madeira on 07/05/23.
//

import SwiftUI

struct CompaniesListView: View {
    let companies: [ProductionCompany]
    var body: some View {
        Form {
            if companies.isEmpty {
                ContentUnavailableView("No Companies", systemImage: "building.2")
            } else {
                Section {
                    List(companies, id: \.self) { item in
                        NavigationLink(value: item) {
                            Text(item.name)
                        }
                    }
                }
            }
        }
        .navigationTitle("Companies")
#if os(macOS)
        .formStyle(.grouped)
#elseif os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
        .scrollBounceBehavior(.basedOnSize)
    }
}
