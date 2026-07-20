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
            return .title3
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
        static let heroHeightPad: CGFloat = 520
        static let heroHeightMac: CGFloat = 380
        static let heroHeightTV: CGFloat = 560
        static let heroHeightCompact: CGFloat = 320
        static let detailHeroHeightPhone: CGFloat = 460
        static let detailHeroHeightPad: CGFloat = 520
        static let detailHeroHeightMac: CGFloat = 420
        static let detailHeroHeightTV: CGFloat = 540

        /// Back-compat alias used by phone details.
        static let detailHeroHeight: CGFloat = detailHeroHeightPhone

        static var homeHeroHeight: CGFloat {
#if os(tvOS)
            return heroHeightTV
#elseif os(macOS)
            return heroHeightMac
#elseif os(iOS)
            return UIDevice.isIPad ? heroHeightPad : heroHeightPhone
#else
            return heroHeightPhone
#endif
        }

        static var detailHeroHeightForPlatform: CGFloat {
#if os(tvOS)
            return detailHeroHeightTV
#elseif os(macOS)
            return detailHeroHeightMac
#elseif os(iOS)
            return UIDevice.isIPad ? detailHeroHeightPad : detailHeroHeightPhone
#else
            return detailHeroHeightPhone
#endif
        }

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
#if os(tvOS)
        self.background(
            .regularMaterial,
            in: RoundedRectangle(cornerRadius: CronicaDesign.Radius.media, style: .continuous)
        )
#else
        self.background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: CronicaDesign.Radius.media, style: .continuous)
        )
#endif
    }

    /// Shared presentation chrome for filter / picker sheets.
    func cronicaFilterSheet() -> some View {
#if os(tvOS)
        self
#else
        self
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(CronicaDesign.Radius.large)
            .presentationBackground(.ultraThinMaterial)
#endif
    }
}

// MARK: - Filter chrome (Apple TV–inspired)

struct CronicaFilterSectionTitle: View {
    let title: String
    var body: some View {
        Text(title)
            .font(CronicaDesign.Typography.sectionTitle())
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, CronicaDesign.Spacing.md)
            .padding(.top, CronicaDesign.Spacing.sm)
            .padding(.bottom, CronicaDesign.Spacing.xxs)
            .accessibilityAddTraits(.isHeader)
    }
}

struct CronicaFilterChip: View {
    let title: String
    let isSelected: Bool
    var action: () -> Void
    @StateObject private var settings = SettingsStore.shared

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(CronicaDesign.Typography.caption())
                .fontWeight(isSelected ? .semibold : .medium)
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, CronicaDesign.Spacing.sm)
                .padding(.vertical, CronicaDesign.Spacing.xs)
                .background {
                    RoundedRectangle(cornerRadius: CronicaDesign.Radius.media, style: .continuous)
                        .fill(isSelected ? settings.appTheme.color : Color.secondary.opacity(0.16))
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

struct CronicaFilterToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title)
                .font(CronicaDesign.Typography.body())
        }
        .padding(.horizontal, CronicaDesign.Spacing.md)
        .padding(.vertical, CronicaDesign.Spacing.sm)
        .cronicaGlassSurface()
        .padding(.horizontal, CronicaDesign.Spacing.md)
    }
}
