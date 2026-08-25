//
//  CriticScoresSection.swift
//  Cronica
//

import SwiftUI

struct CriticScoresSection: View {
    let ratings: ExternalCriticRatings?
    let fallbackTMDB: String?

    var body: some View {
        if let ratings, ratings.hasAnyScore {
            if let tmdb = ratings.tmdb ?? fallbackTMDB {
                CriticScoreRow(title: String(localized: "Ratings Score"), value: tmdb)
            }
            if let rottenTomatoes = ratings.rottenTomatoes {
                CriticScoreRow(title: String(localized: "Rotten Tomatoes"), value: rottenTomatoes)
            }
            if let metacritic = ratings.metacritic {
                CriticScoreRow(title: String(localized: "Metacritic"), value: metacritic)
            }
            if let letterboxd = ratings.letterboxd {
                CriticScoreRow(title: String(localized: "Letterboxd"), value: letterboxd)
            }
        } else if let fallbackTMDB, !fallbackTMDB.isEmpty {
            CriticScoreRow(title: String(localized: "Ratings Score"), value: fallbackTMDB)
        }
    }
}

private struct CriticScoreRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                Text(value)
                    .multilineTextAlignment(.leading)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
            Spacer()
        }
        .padding([.horizontal, .top], 2)
    }
}
