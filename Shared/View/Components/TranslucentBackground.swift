//
//  TranslucentBackground.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 19/11/22.
//

import SwiftUI
import NukeUI

@available(watchOS 10.0, *)
struct TranslucentBackground: View {
    var image: URL?
    @AppStorage("disableTranslucentBackground") private var disableTranslucent = false
    var useLighterMaterial = false
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    var body: some View {
        if !disableTranslucent && !reduceTransparency && image != nil {
            ZStack {
                LazyImage(url: image) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle()
                            .fill(.background)
                            .ignoresSafeArea()
                            .padding(.zero)
                    }
                }
                .ignoresSafeArea()
                .padding(.zero)
                .transition(.opacity)

                LinearGradient(
                    colors: [
                        .black.opacity(0.15),
                        .clear,
                        .black.opacity(0.25)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)

#if os(watchOS)
                Rectangle()
                    .fill(.thickMaterial)
                    .ignoresSafeArea()
                    .padding(.zero)
#elseif os(macOS) || os(iOS)
                Rectangle()
                    .fill(useLighterMaterial ? .regularMaterial : .ultraThickMaterial)
                    .ignoresSafeArea()
                    .padding(.zero)
#else
                Rectangle()
                    .fill(.thickMaterial)
                    .ignoresSafeArea()
                    .padding(.zero)
#endif
            }
        }
    }
}
