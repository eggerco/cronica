//
//  ItemContentHeroHeader.swift
//  Cronica
//

import NukeUI
import SwiftUI

#if os(iOS)
struct ItemContentHeroHeader: View {
    let posterURL: URL?
    let posterWidth: CGFloat
    let posterHeight: CGFloat

    var body: some View {
        poster
            .padding(.top, 12)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)
    }

    private var poster: some View {
        LazyImage(url: posterURL) { state in
            if let image = state.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    Rectangle().fill(.gray.gradient)
                    Image(systemName: "popcorn.fill")
                        .font(.title)
                        .fontWidth(.expanded)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .frame(width: posterWidth, height: posterHeight)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 10, y: 6)
    }
}
#endif
