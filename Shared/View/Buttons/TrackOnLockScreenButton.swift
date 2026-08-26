//
//  TrackOnLockScreenButton.swift
//  Cronica (iOS)
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

#if os(iOS)
struct TrackOnLockScreenButton: View {
    let contentID: String
    @ObservedObject private var session = WatchingSessionManager.shared
    @State private var alertMessage: String?
    @State private var showSettingsButton = false
    private let persistence = PersistenceController.shared

    var body: some View {
        if #available(iOS 16.2, *) {
            Button {
                Task { await toggleTracking() }
            } label: {
                Label(
                    session.isTracking(contentID: contentID)
                        ? String(localized: "Stop Lock Screen Tracking")
                        : String(localized: "Track on Lock Screen"),
                    systemImage: session.isTracking(contentID: contentID) ? "stop.circle" : "play.circle"
                )
            }
            .alert(
                String(localized: "Lock Screen Tracking"),
                isPresented: Binding(
                    get: { alertMessage != nil },
                    set: { if !$0 { alertMessage = nil } }
                )
            ) {
                if showSettingsButton {
                    Button(String(localized: "Open Settings")) {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                Button(String(localized: "OK"), role: .cancel) {}
            } message: {
                Text(alertMessage ?? "")
            }
        }
    }

    @available(iOS 16.2, *)
    private func toggleTracking() async {
        guard let item = persistence.fetch(for: contentID) else {
            showSettingsButton = false
            alertMessage = String(localized: "Add this title to your watchlist first, then try again.")
            return
        }

        let result = await session.toggle(for: item)
        switch result {
        case .started:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .stopped:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .disabled:
            showSettingsButton = true
            alertMessage = session.lastErrorMessage
                ?? String(localized: "Turn on Live Activities for Cronica in Settings to track on the Lock Screen.")
        case .failed:
            showSettingsButton = false
            alertMessage = session.lastErrorMessage
                ?? String(localized: "Couldn't start Lock Screen tracking. Try again in a moment.")
        case .unavailable:
            showSettingsButton = false
            alertMessage = String(localized: "Lock Screen tracking isn't available right now.")
        }
    }
}
#endif
