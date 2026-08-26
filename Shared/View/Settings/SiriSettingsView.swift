//
//  SiriSettingsView.swift
//  Cronica
//

import SwiftUI

#if canImport(AppIntents) && !os(watchOS) && !os(tvOS)
import AppIntents

struct SiriSettingsView: View {
    var body: some View {
        List {
            Section {
#if os(iOS) || os(visionOS)
                ShortcutsLink {
                    Label(String(localized: "Browse Cronica Shortcuts"), systemImage: "square.grid.2x2")
                }
#else
                Text(String(localized: "Open the Shortcuts app to browse Cronica actions and add them to Siri."))
#endif
            } footer: {
                Text(String(localized: "Use Siri and the Shortcuts app to add titles, mark episodes watched, check what's up next, and open movies or shows in Cronica."))
            }

            Section(String(localized: "Example phrases")) {
                Label(String(localized: "“Add Dune to Cronica”"), systemImage: "plus.circle")
                Label(String(localized: "“What's up next on Cronica?”"), systemImage: "text.line.first.and.arrowtriangle.forward")
                Label(String(localized: "“Mark my next episode as watched”"), systemImage: "play.circle")
                Label(String(localized: "“Open Severance in Cronica”"), systemImage: "arrow.up.forward.app")
            }
        }
        .navigationTitle(String(localized: "Siri & Shortcuts"))
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
}
#endif
