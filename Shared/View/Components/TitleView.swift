//
//  TitleView.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 03/04/22.
//

import SwiftUI

struct TitleView: View {
    let title: String
    var subtitle: String?
    var showChevron = false
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: CronicaDesign.Spacing.xxs) {
                HStack(spacing: CronicaDesign.Spacing.xs) {
                    Text(title)
                        .font(CronicaDesign.Typography.sectionTitle())
                        .foregroundStyle(.primary)
                    if showChevron {
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                    }
                }
                if let subtitle {
                    Text(subtitle)
                        .font(CronicaDesign.Typography.sectionSubtitle())
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, CronicaDesign.Spacing.md)
        .padding(.top, CronicaDesign.Spacing.sm)
        .padding(.bottom, CronicaDesign.Spacing.xxs)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    TitleView(title: "Coming Soon", subtitle: "From Watchlist", showChevron: true)
}
