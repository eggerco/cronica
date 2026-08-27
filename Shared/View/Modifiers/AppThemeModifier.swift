//
//  AppThemeModifier.swift
//  Cronica
//
//  Created by Alexandre Madeira on 03/01/23.
//

import SwiftUI

struct AppThemeModifier: ViewModifier {
    static let defaultsKey = "user_theme"
    @StateObject private var settings = SettingsStore.shared
    @AppStorage(Self.defaultsKey) private var currentTheme: AppTheme = .system
    @Environment(\.colorScheme) var systemTheme
    func body(content: Content) -> some View {
        content
            .environment(\.colorScheme, currentTheme.overrideTheme ?? systemTheme)
    }
}

struct AppTintModifier: ViewModifier {
    @AppStorage(AccentColorStorage.hexDefaultsKey) private var accentColorHex = AccentColorStorage.defaultHex

    func body(content: Content) -> some View {
        content
            .tint(Color(cronicaHex: accentColorHex) ?? AccentColorStorage.defaultColor)
    }
}
