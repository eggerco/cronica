//
//  CronicaLoadingPopupView.swift
//  Story (iOS)
//
//  Created by Alexandre Madeira on 23/01/24.
//

import SwiftUI

struct CronicaLoadingPopupView: View {
    var body: some View {
        HStack(alignment: .center) {
            VStack {
                ProgressView("Loading")
                    .fontDesign(.rounded)
                    .fontWeight(.semibold)
                    .fontDesign(.rounded)
                    .tint(.secondary)
                    .padding()
            }
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: CronicaDesign.Radius.large, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CronicaDesign.Radius.large, style: .continuous)
                    .stroke(Color.black.opacity(0.2), lineWidth: 0.3)
            )
#if os(watchOS)
            .frame(width: 100, height: 80, alignment: .center)
#else
            .frame(width: 180, height: 150, alignment: .center)
#endif
            .unredacted()
        }
        .frame(maxWidth: .infinity)
    }
}
