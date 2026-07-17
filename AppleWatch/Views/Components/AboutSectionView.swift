//
//  AboutSectionView.swift
//  Cronica Watch App
//
//  Created by Alexandre Madeira on 29/09/22.
//

import SwiftUI

struct AboutSectionView: View {
    let about: String?
    @State private var showAbout = false
    var body: some View {
        if let about {
            if !about.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: CronicaDesign.Spacing.xxs) {
                        Text(about)
                            .font(CronicaDesign.Typography.caption())
                            .lineLimit(showAbout ? nil : 4)
                    }
                    .onTapGesture {
                        withAnimation(CronicaDesign.Motion.standard) { showAbout.toggle() }
                    }
                    .padding(.zero)
                } header: {
                    HStack {
                        Text("About")
                            .font(CronicaDesign.Typography.caption())
                            .textCase(.uppercase)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, CronicaDesign.Spacing.sm)
                    .padding(.top, CronicaDesign.Spacing.sm)
                }
                .padding(.horizontal, CronicaDesign.Spacing.sm)
                .padding(.bottom, CronicaDesign.Spacing.sm)
            }
        }
    }
}

#Preview {
    AboutSectionView(about: ItemContent.example.itemOverview)
}
