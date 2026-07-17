//
//  HomeBrandHeader.swift
//  Cronica
//
//  First-viewport brand composition for Home.
//

import SwiftUI
import NukeUI

#if !os(watchOS)
struct HomeBrandHeader: View {
    var featuredImage: URL?
    var featuredTitle: String?
    var height: CGFloat = CronicaDesign.Atmosphere.homeHeroHeight
    var compactCopy = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    @StateObject private var store = SettingsStore.shared

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            heroArtwork
            CronicaDesign.Atmosphere.gradient
                .allowsHitTesting(false)
            copyBlock
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, CronicaDesign.Spacing.lg)
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipped()
#if os(tvOS)
        .focusable(false)
#endif
        .onAppear {
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(CronicaDesign.Motion.hero) {
                    appeared = true
                }
            }
        }
    }

    private var horizontalPadding: CGFloat {
#if os(tvOS)
        return 64
#else
        return CronicaDesign.Spacing.lg
#endif
    }

    @ViewBuilder
    private var heroArtwork: some View {
        if let featuredImage {
            LazyImage(url: featuredImage) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .scaleEffect(appeared && !reduceMotion ? 1.04 : 1)
                } else {
                    fallbackAtmosphere
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            fallbackAtmosphere
        }
    }

    private var fallbackAtmosphere: some View {
        ZStack {
            LinearGradient(
                colors: [
                    store.appTheme.color.opacity(0.55),
                    Color(white: 0.12),
                    .black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "popcorn.fill")
                .font(.system(size: compactCopy ? 56 : 72, weight: .semibold))
                .foregroundStyle(.white.opacity(0.12))
                .offset(x: 80, y: -40)
        }
    }

    private var copyBlock: some View {
        VStack(alignment: .leading, spacing: CronicaDesign.Spacing.xs) {
            Text("Cronica")
                .font(CronicaDesign.Typography.brand())
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.35), radius: 8, y: 2)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

            Text(headline)
                .font(CronicaDesign.Typography.display())
                .foregroundStyle(.white)
                .lineLimit(compactCopy ? 1 : 2)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)

            if !compactCopy {
                Text(supporting)
                    .font(CronicaDesign.Typography.sectionSubtitle())
                    .foregroundStyle(.white.opacity(0.82))
                    .lineLimit(2)
                    .opacity(appeared ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var headline: String {
        if let featuredTitle, !featuredTitle.isEmpty {
            return featuredTitle
        }
        return String(localized: "Your watchlist, on schedule")
    }

    private var supporting: String {
        if featuredTitle != nil {
            return String(localized: "Up next from your list")
        }
        return String(localized: "Track releases and pick up where you left off.")
    }
}

#Preview {
    HomeBrandHeader(featuredImage: ItemContent.example.cardImageLarge,
                    featuredTitle: ItemContent.example.itemTitle)
}
#endif
