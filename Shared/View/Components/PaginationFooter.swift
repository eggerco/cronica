//
//  PaginationFooter.swift
//  Cronica
//

import SwiftUI

/// Shared infinite-scroll footer that loads the next page as soon as it appears.
struct PaginationFooter: View {
    var label: String? = nil
    let onAppear: () -> Void

    var body: some View {
        CenterHorizontalView {
            Group {
                if let label {
                    ProgressView(label)
                } else {
                    ProgressView()
                }
            }
            .padding()
            .onAppear(perform: onAppear)
        }
    }
}
