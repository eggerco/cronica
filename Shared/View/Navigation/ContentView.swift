//
//  ContentView.swift
//  Shared
//
//  Created by Alexandre Madeira on 14/01/22.
//

import SwiftUI

struct ContentView: View {
    private var persistence = PersistenceController.shared

    var body: some View {
        rootView
            .appTheme()
            .appTint()
            .overlay {
                if persistence.didFailToLoadStore {
                    ContentUnavailableView {
                        Label(
                            String(localized: "Couldn't Load Library"),
                            systemImage: "exclamationmark.triangle"
                        )
                    } description: {
                        Text(String(localized: "Restart Cronica. If this keeps happening, contact support."))
                    }
                }
            }
    }

    @ViewBuilder
    private var rootView: some View {
#if os(iOS) || os(tvOS) || os(visionOS)
        TabBarView()
#elseif os(macOS)
        SideBarView()
#endif
    }
}

#Preview {
    ContentView()
}
