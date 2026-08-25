//
//  MuteNotificationsButton.swift
//  Cronica
//

import SwiftUI

struct MuteNotificationsButton: View {
    let id: String
    @Binding var isMuted: Bool
    private let persistence = PersistenceController.shared

    var body: some View {
        Button(isMuted ? "Unmute Notifications" : "Mute Notifications",
               systemImage: isMuted ? "bell.slash.fill" : "bell.slash",
               action: updateMute)
    }

    private func updateMute() {
        guard let item = persistence.fetch(for: id) else { return }
        let willMute = !isMuted
        persistence.updateNotificationsMuted(for: item, muted: willMute)
        withAnimation { isMuted = willMute }
        if !willMute {
            Task {
                guard let content = try? await NetworkService.shared.fetchItem(id: item.itemId, type: item.itemMedia) else {
                    return
                }
                // schedule() only creates future notifications within the existing window.
                NotificationManager.shared.schedule(content)
            }
        }
    }
}

#Preview {
    MuteNotificationsButton(id: ItemContent.example.itemContentID, isMuted: .constant(false))
}
