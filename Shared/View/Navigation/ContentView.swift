//
//  ContentView.swift
//  Shared
//
//  Created by Alexandre Madeira on 14/01/22.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        rootView
            .appTheme()
            .appTint()
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
