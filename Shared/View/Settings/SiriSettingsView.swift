//
//  SiriSettingsView.swift
//  Cronica
//

import SwiftUI

#if canImport(AppIntents) && !os(watchOS) && !os(tvOS)
struct SiriSettingsView: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        List {
            Section {
#if os(iOS) || os(visionOS)
                Button {
                    if let url = URL(string: "shortcuts://") {
                        openURL(url)
                    }
                } label: {
                    Label(String(localized: "Open Shortcuts"), systemImage: "square.stack.3d.up.fill")
                }
#else
                Text(String(localized: "Open the Shortcuts app to browse Cronica actions and add them to Siri."))
#endif
            } header: {
                Text(String(localized: "Shortcuts"))
            } footer: {
                Text(String(localized: "Use Siri and the Shortcuts app to add titles, mark episodes watched, check what's up next, and open movies or shows in Cronica."))
            }

            Section(String(localized: "Example phrases")) {
                Label(String(localized: "“Add Dune to Cronica”"), systemImage: "plus.circle")
                Label(String(localized: "“What's up next on Cronica?”"), systemImage: "text.line.first.and.arrowtriangle.forward")
                Label(String(localized: "“Mark my next episode as watched”"), systemImage: "play.circle")
                Label(String(localized: "“Open Severance in Cronica”"), systemImage: "arrow.up.forward.app")
                Label(String(localized: "“Open my watchlist in Cronica”"), systemImage: "rectangle.on.rectangle")
                Label(String(localized: "“Open up next in Cronica”"), systemImage: "play.tv")
            }

#if os(iOS)
            Section(String(localized: "Control Center")) {
                Text(String(localized: "On iOS 18 or later, add Cronica controls from Settings → Control Center for Up Next and Mark Watched."))
            }
#endif
        }
        .navigationTitle(String(localized: "Siri & Shortcuts"))
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .onAppear {
            SiriShortcutRefreshBridge.refreshIfAvailable()
        }
    }
}
#endif
