//
//  CriticScoresSection.swift
//  Cronica
//

import SwiftUI

struct CriticScoresSection: View {
    let ratings: ExternalCriticRatings?
    let fallbackTMDB: String?

    private struct ScoreItem: Identifiable {
        let id: String
        let label: String
        let value: String
        let symbol: String
    }

    private var items: [ScoreItem] {
        var result: [ScoreItem] = []
        if let ratings {
            if let rottenTomatoes = ratings.rottenTomatoes {
                result.append(.init(
                    id: "rt",
                    label: String(localized: "Critics"),
                    value: rottenTomatoes,
                    symbol: "checkmark.seal.fill"
                ))
            }
            if let metacritic = ratings.metacritic {
                result.append(.init(
                    id: "mc",
                    label: String(localized: "Metacritic"),
                    value: metacritic,
                    symbol: "chart.bar.fill"
                ))
            }
            if let letterboxd = ratings.letterboxd {
                result.append(.init(
                    id: "lb",
                    label: String(localized: "Letterboxd"),
                    value: letterboxd,
                    symbol: "film.fill"
                ))
            }
            if let tmdb = ratings.tmdb ?? fallbackTMDB, !tmdb.isEmpty {
                result.append(.init(
                    id: "tmdb",
                    label: String(localized: "TMDB"),
                    value: tmdb,
                    symbol: "star.fill"
                ))
            }
        } else if let fallbackTMDB, !fallbackTMDB.isEmpty {
            result.append(.init(
                id: "tmdb",
                label: String(localized: "TMDB"),
                value: fallbackTMDB,
                symbol: "star.fill"
            ))
        }
        return result
    }

    var body: some View {
        if !items.isEmpty {
            HStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    scoreColumn(item)
                    if index < items.count - 1 {
                        Divider()
                            .frame(height: 28)
                            .padding(.horizontal, 4)
                    }
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
            .accessibilityElement(children: .contain)
            .accessibilityLabel(String(localized: "Scores"))
        }
    }

    private func scoreColumn(_ item: ScoreItem) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: item.symbol)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(item.label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Text(item.value)
                .font(.subheadline.weight(.semibold))
                .fontDesign(.rounded)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
