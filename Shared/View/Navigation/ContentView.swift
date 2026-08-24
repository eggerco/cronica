//
//  ContentView.swift
//  Shared
//
//  Created by Alexandre Madeira on 14/01/22.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
#if os(iOS) || os(tvOS) || os(visionOS)
        TabBarView()
#elseif os(macOS)
        SideBarView()
#endif
        .appTheme()
        .appTint()
    }
}

#Preview {
    ContentView()
}
