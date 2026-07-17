//
//  PosterPlaceholder.swift
//  Cronica
//
//  Created by Alexandre Madeira on 07/05/23.
//

import SwiftUI

struct PosterPlaceholder: View {
    var title: String
    let type: MediaType
    @StateObject private var settings = SettingsStore.shared
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(white: 0.22),
                    Color(white: 0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: CronicaDesign.Spacing.xs) {
                if settings.isCompactUI {
                    Image(systemName: "popcorn.fill")
                        .font(.title3)
                        .fontWidth(.expanded)
                        .foregroundStyle(.white.opacity(0.8))
                        .padding()
                } else {
                    Image(systemName: "popcorn.fill")
                        .font(.title)
                        .fontWidth(.expanded)
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.top)
                    Text(title)
                        .font(CronicaDesign.Typography.caption())
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                        .padding(.horizontal, 4)
                }
            }
        }
        .frame(width: settings.isCompactUI ? DrawingConstants.compactPosterWidth : DrawingConstants.posterWidth,
               height: settings.isCompactUI ? DrawingConstants.compactPosterHeight : DrawingConstants.posterHeight)
        .clipShape(RoundedRectangle(cornerRadius: settings.isCompactUI ? CronicaDesign.Radius.compact : CronicaDesign.Radius.media,
                                    style: .continuous))
        .shadow(
            color: .black.opacity(CronicaDesign.Shadow.mediaOpacity),
            radius: CronicaDesign.Shadow.mediaRadius,
            x: 0,
            y: CronicaDesign.Shadow.mediaY
        )
    }
}

private struct DrawingConstants {
#if os(tvOS)
    static let posterWidth: CGFloat = 260
    static let posterHeight: CGFloat = 380
#else
    static let posterWidth: CGFloat = 160
    static let posterHeight: CGFloat = 240
#endif
    static let compactPosterWidth: CGFloat = 80
    static let compactPosterHeight: CGFloat = 140
}

#Preview {
    PosterPlaceholder(title: "Preview", type: .movie)
}
