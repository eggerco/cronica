//
//  ItemContentHeroHeader.swift
//  Cronica
//

import NukeUI
import SwiftUI

#if os(iOS)
struct ItemContentHeroHeader: View {
    let backdropURL: URL?
    let posterURL: URL?
    let posterWidth: CGFloat
    let posterHeight: CGFloat

    var body: some View {
        ZStack(alignment: .bottom) {
            heroBackdrop
            poster
                .padding(.bottom, 24)
        }
        .frame(height: posterHeight + 96)
        .accessibilityHidden(true)
    }

    private var heroBackdrop: some View {
        GeometryReader { proxy in
            ZStack {
                LazyImage(url: backdropURL) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .blur(radius: 28, opaque: true)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(.quaternary.opacity(0.4))
                    }
                }
                LinearGradient(
                    colors: [
                        .black.opacity(0.15),
                        .black.opacity(0.45),
                        Color(uiColor: .systemBackground).opacity(0.92),
                        Color(uiColor: .systemBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .ignoresSafeArea(edges: .top)
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
        .shadow(color: .black.opacity(0.35), radius: 16, y: 10)
    }
}
#endif
