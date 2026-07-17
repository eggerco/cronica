//
//  CronicaDesign.swift
//  Cronica
//
//  Shared visual tokens for the cinematic redesign.
//

import SwiftUI

enum CronicaDesign {
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    enum Radius {
        static let compact: CGFloat = 6
        static let media: CGFloat = 14
        static let large: CGFloat = 20
        static let hero: CGFloat = 0
    }

    enum Shadow {
        static let mediaOpacity: Double = 0.18
        static let mediaRadius: CGFloat = 8
        static let mediaY: CGFloat = 4
    }

    enum Typography {
        static func brand() -> Font {
#if os(watchOS) || os(tvOS)
            return .largeTitle.weight(.bold)
#else
            return .system(.largeTitle, design: .serif).weight(.bold)
#endif
        }

        static func display() -> Font {
#if os(watchOS) || os(tvOS)
            return .title2.weight(.semibold)
#else
            return .system(.title2, design: .serif).weight(.semibold)
#endif
        }

        static func sectionTitle() -> Font {
#if os(watchOS) || os(tvOS)
            return .headline.weight(.semibold)
#else
            return .system(.title3, design: .serif).weight(.semibold)
#endif
        }

        static func sectionSubtitle() -> Font {
#if os(tvOS)
            return .caption
#else
            return .subheadline
#endif
        }

        static func body() -> Font {
            .body
        }

        static func caption() -> Font {
            .caption
        }
    }

    enum Motion {
        static let standard = Animation.easeOut(duration: 0.45)
        static let gentle = Animation.easeInOut(duration: 0.55)
        static let hero = Animation.easeOut(duration: 0.7)

        static func reduced(_ reduceMotion: Bool) -> Animation? {
            reduceMotion ? nil : standard
        }
    }

    enum Atmosphere {
        static let heroHeightPhone: CGFloat = 420
        static let heroHeightCompact: CGFloat = 320
        static let detailHeroHeight: CGFloat = 460
        static let gradient = LinearGradient(
            colors: [
                .black.opacity(0.05),
                .black.opacity(0.35),
                .black.opacity(0.85)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

extension View {
    func cronicaMediaChrome(cornerRadius: CGFloat = CronicaDesign.Radius.media) -> some View {
        self
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(
                color: .black.opacity(CronicaDesign.Shadow.mediaOpacity),
                radius: CronicaDesign.Shadow.mediaRadius,
                x: 0,
                y: CronicaDesign.Shadow.mediaY
            )
    }

    func cronicaGlassSurface() -> some View {
        self.background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: CronicaDesign.Radius.media, style: .continuous)
        )
    }
}
