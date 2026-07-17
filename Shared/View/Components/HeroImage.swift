//
//  HeroImage.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 05/04/22.
//

import SwiftUI
import NukeUI

struct HeroImage: View {
    let url: URL?
    let title: String
    var type: MediaType = .movie
    var fullBleed = false
    var body: some View {
        LazyImage(url: url) { state in
            if let image = state.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(white: 0.18),
                            Color(white: 0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    VStack(spacing: CronicaDesign.Spacing.sm) {
                        Image(systemName: "popcorn.fill")
                            .font(.largeTitle)
                            .fontWidth(.expanded)
                            .foregroundStyle(.white.opacity(0.75))
                        if !fullBleed {
                            Text(title)
                                .font(CronicaDesign.Typography.sectionSubtitle())
                                .foregroundStyle(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .padding(.horizontal)
                        }
                    }
                    .unredacted()
                }
                .transition(.opacity)
            }
        }
        .transition(.opacity)
#if os(watchOS)
        .frame(height: 90)
        .clipShape(
            RoundedRectangle(cornerRadius: 8,
                             style: .continuous)
        )
        .padding()
#endif
    }
}

#Preview {
    HeroImage(url: ItemContent.example.cardImageLarge,
              title: ItemContent.example.itemTitle,
              fullBleed: true)
}
