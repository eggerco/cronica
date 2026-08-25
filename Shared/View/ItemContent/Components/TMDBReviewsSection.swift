//
//  TMDBReviewsSection.swift
//  Cronica
//

import CronicaCore
import SwiftUI

struct TMDBReviewsSection: View {
    let reviews: [TMDBReview]
    let communityScore: String?

    private var averageReviewScore: String? {
        reviews.averageRatingLabel
    }

    var body: some View {
        if hasSummary || !reviews.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                if hasSummary {
                    summaryRow
                }
                ForEach(reviews.prefix(3)) { review in
                    reviewCard(review)
                }
            }
        }
    }

    private var hasSummary: Bool {
        communityScore != nil || averageReviewScore != nil
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

    private func reviewCard(_ review: TMDBReview) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                reviewAvatar(review)
                VStack(alignment: .leading, spacing: 4) {
                    Text(review.displayName)
                        .font(.subheadline.weight(.semibold))
                        .fontDesign(.rounded)
                    if let rating = review.authorDetails?.rating {
                        TMDBReviewStars(rating: rating)
                    }
                }
                Spacer(minLength: 0)
            }
            Text(review.content.trimmingCharacters(in: .whitespacesAndNewlines))
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(4)
                .multilineTextAlignment(.leading)
            if let urlString = review.url, let url = URL(string: urlString) {
                Link(String(localized: "Read on TMDB"), destination: url)
                    .font(.caption.weight(.medium))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.quaternary, lineWidth: 0.5)
        }
    }

    @ViewBuilder
    private func reviewAvatar(_ review: TMDBReview) -> some View {
        if let url = review.avatarURL {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 34, height: 34)
            .clipShape(Circle())
        } else {
            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }
}

private struct TMDBReviewStars: View {
    let rating: Double

    private var filledStars: Int {
        Int((rating / 2.0).rounded())
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: index <= filledStars ? "star.fill" : "star")
                    .font(.caption2)
                    .foregroundStyle(index <= filledStars ? .yellow : .secondary.opacity(0.35))
            }
            if let label = ratingLabel {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityLabel(String(format: String(localized: "Rated %.1f out of 10"), rating))
    }

    private var ratingLabel: String? {
        String(format: "%.1f/10", rating)
    }
}
