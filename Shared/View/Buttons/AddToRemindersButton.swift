//
//  AddToRemindersButton.swift
//  Cronica
//

import SwiftUI

struct AddToRemindersButton: View {
    let contentID: String
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false

    var body: some View {
        Button {
            Task { await addReminder() }
        } label: {
            Label(String(localized: "Add to Reminders"), systemImage: "checklist")
        }
        .alert(String(localized: "Couldn't Add Reminder"), isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert(String(localized: "Added to Reminders"), isPresented: $showSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(String(localized: "Cronica added a reminder for the next release or episode."))
        }
    }

    @MainActor
    private func addReminder() async {
#if canImport(EventKit) && !os(tvOS) && !os(watchOS)
        guard let item = PersistenceController.shared.fetch(for: contentID) else {
            errorMessage = String(localized: "That title isn't on your watchlist.")
            showError = true
            return
        }
        do {
            try await RemindersManager.shared.addReminder(for: item)
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
#else
        errorMessage = String(localized: "Reminders aren't available on this device.")
        showError = true
#endif
    }
}
