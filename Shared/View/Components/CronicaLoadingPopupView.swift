//
//  CronicaLoadingPopupView.swift
//  Story (iOS)
//
//  Created by Alexandre Madeira on 23/01/24.
//

import SwiftUI

struct CronicaLoadingPopupView: View {
    var body: some View {
        ProgressView()
            .controlSize(.large)
            .padding(20)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .unredacted()
    }
}
