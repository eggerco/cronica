//
//  TMDBReviewsSection.swift
//  Cronica
//

import SwiftUI

struct TMDBReviewsSection: View {
    let communityScore: String?
    let averageReviewScore: String?

    var body: some View {
        if communityScore != nil || averageReviewScore != nil {
            summaryRow
        }
    }

    private var summaryRow: some View {
        HStack(spacing: 0) {
            if let communityScore {
                summaryColumn(
                    title: String(localized: "TMDB"),
                    value: communityScore,
                    symbol: "star.fill"
                )
            }
            if communityScore != nil, averageReviewScore != nil {
                Divider()
                    .frame(height: 28)
                    .padding(.horizontal, 4)
            }
            if let averageReviewScore {
                summaryColumn(
                    title: String(localized: "Reviews"),
                    value: averageReviewScore,
                    symbol: "text.bubble.fill"
                )
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.quaternary, lineWidth: 0.5)
        }
    }

    private func summaryColumn(title: String, value: String, symbol: String) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.subheadline.weight(.semibold))
                .fontDesign(.rounded)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
