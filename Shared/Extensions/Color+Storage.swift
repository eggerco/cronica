//
//  Color+Storage.swift
//  Cronica
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum AccentColorStorage {
    static let hexDefaultsKey = "appAccentColorHex"
    static let legacyDefaultsKey = "appThemeColor"
    /// Approximate system blue — used when nothing is stored yet.
    static let defaultHex = "007AFF"

    static var defaultColor: Color {
        Color(cronicaHex: defaultHex) ?? .blue
    }

    /// One-time migration from the old preset enum (`appThemeColor` Int).
    static func migrateLegacyIfNeeded(defaults: UserDefaults = .standard) {
        guard defaults.object(forKey: hexDefaultsKey) == nil else { return }
        let raw = defaults.object(forKey: legacyDefaultsKey) as? Int ?? 0
        let legacy = AppThemeColors(rawValue: raw)?.color ?? defaultColor
        defaults.set(legacy.cronicaHex ?? defaultHex, forKey: hexDefaultsKey)
    }
}

extension Color {
    init?(cronicaHex: String) {
        var hex = cronicaHex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard hex.count == 6, let int = UInt64(hex, radix: 16) else { return nil }
        self.init(
            red: Double((int >> 16) & 0xFF) / 255,
            green: Double((int >> 8) & 0xFF) / 255,
            blue: Double(int & 0xFF) / 255
        )
    }

    var cronicaHex: String? {
#if canImport(UIKit)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        guard UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        return String(format: "%02X%02X%02X", Int((r * 255).rounded()), Int((g * 255).rounded()), Int((b * 255).rounded()))
#elseif canImport(AppKit)
        guard let rgb = NSColor(self).usingColorSpace(.deviceRGB) else { return nil }
        return String(
            format: "%02X%02X%02X",
            Int((rgb.redComponent * 255).rounded()),
            Int((rgb.greenComponent * 255).rounded()),
            Int((rgb.blueComponent * 255).rounded())
        )
#else
        return nil
#endif
    }
}
