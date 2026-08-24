//
//  PaginationFooter.swift
//  Cronica
//

import SwiftUI

/// Shared infinite-scroll footer. Skips firing while a page request is already in flight.
struct PaginationFooter: View {
    var label: String? = nil
    var isLoadingMore: Bool = false
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
            .onAppear {
                guard !isLoadingMore else { return }
                onAppear()
            }
        }
        .accessibilityLabel(String(localized: "Loading more"))
    }
}
