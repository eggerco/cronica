//
//  TMDBCatalogUnavailableView.swift
//  Cronica
//

import SwiftUI
import CronicaCore

/// Catalog empty-state that upgrades generic connection copy when TMDB looks blocked.
struct TMDBCatalogUnavailableView: View {
    var title: String = String(localized: "Couldn't Load")
    var failure: TMDBConnectionFailure?
    var fallbackMessage: String = String(localized: "Check your connection and try again.")
    var retry: () -> Void
    @State private var showHelp = false

    private var displayTitle: String {
        failure?.title ?? title
    }

    private var displayMessage: String {
        if let failure {
            return failure.message
        }
        return fallbackMessage
    }

    var body: some View {
        ContentUnavailableView {
            Label(displayTitle, systemImage: "wifi.exclamationmark")
        } description: {
            Text(displayMessage)
        } actions: {
            Button("Retry", action: retry)
                .buttonStyle(.borderedProminent)
            if failure?.showsRegionHelp == true {
                Button("Why this happens") { showHelp = true }
            }
        }
        .sheet(isPresented: $showHelp) {
            NavigationStack {
                TMDBUnavailableHelpView()
                    .nativeSheetDismissToolbar { showHelp = false }
            }
#if os(macOS)
            .frame(minWidth: 420, minHeight: 460)
#endif
        }
    }
}

#Preview {
    TMDBCatalogUnavailableView(failure: .unreachable, retry: {})
}
