//
//  AppearanceSetting.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 13/12/22.
//

import SwiftUI

struct AppearanceSetting: View {
    @StateObject private var store = SettingsStore.shared
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        Form {
#if os(iOS)
            if horizontalSizeClass == .compact {
                Section("Details Page") {
                    Toggle("Prefer Poster in Details Page", isOn: $store.usePostersAsCover)
                }
            }
#endif

#if !os(tvOS)
            Section("Style Preferences") {
                Picker(selection: $store.sectionStyleType) {
                    ForEach(SectionDetailsPreferredStyle.allCases) { item in
                        Text(item.title).tag(item)
                    }
                } label: {
                    Text("Section's Details Style")
                }
                Picker(selection: $store.listsDisplayType) {
                    ForEach(ItemContentListPreferredDisplayType.allCases) { item in
                        Text(item.title).tag(item)
                    }
                } label: {
                    Text("Horizontal List Style")
                }
            }
#endif

#if os(iOS)
            if horizontalSizeClass == .compact {
                Section {
                    Toggle(isOn: $store.isCompactUI) {
                        Text("Compact UI")
                        Text("Reduce some UI elements size to accommodate more items on the screen")
                    }
                }
            }
#endif

#if os(iOS) || os(macOS)
            Section {
                Picker("Theme", selection: $store.currentTheme) {
                    ForEach(AppTheme.allCases) { item in
                        Text(item.localizableName).tag(item)
                    }
                }

                Picker("Accent Color", selection: $store.appTheme) {
                    ForEach(AppThemeColors.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
            } header: {
                Text("Appearance")
            }
#endif

            Section {
                Toggle(isOn: $store.disableTranslucent) {
                    Text("Disable Translucent Background")
                }
            }
        }
        .navigationTitle("Appearance")
#if os(macOS)
        .formStyle(.grouped)
#endif
        .tint(store.appTheme.color)
    }
}

#Preview {
    AppearanceSetting()
}
