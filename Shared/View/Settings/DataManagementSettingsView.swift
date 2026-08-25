//
//  DataManagementSettingsView.swift
//  Cronica
//

import SwiftUI

struct DataManagementSettingsView: View {
    @Environment(\.openURL) private var openURL
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var deletionError: String?
    @State private var didDeleteData = false

    var body: some View {
        Form {
            CronicaFormSection("Your Data") {
                CronicaFormText(
                    "Cronica does not use accounts. Your watchlist, ratings, notes, and preferences are stored on this device and, if enabled, in your private iCloud account.",
                    font: .subheadline,
                    color: .secondary
                )
            }

            CronicaFormSection("What Gets Deleted") {
                Label {
                    CronicaFormText("Watchlist items and custom lists")
                } icon: {
                    Image(systemName: "rectangle.on.rectangle")
                }
                Label {
                    CronicaFormText("Episode progress, ratings, and notes")
                } icon: {
                    Image(systemName: "note.text")
                }
                Label {
                    CronicaFormText("Scheduled notifications")
                } icon: {
                    Image(systemName: "bell")
                }
#if !os(tvOS) && !os(watchOS)
                Label {
                    CronicaFormText("Cronica calendar and release events")
                } icon: {
                    Image(systemName: "calendar")
                }
#endif
                Label {
                    CronicaFormText("App preferences and filters")
                } icon: {
                    Image(systemName: "slider.horizontal.3")
                }
            }

            CronicaFormSection("iCloud Sync") {
                CronicaFormText(
                    "If iCloud sync is enabled, deletions will sync to your other Apple devices signed into the same iCloud account. You can also remove Cronica data from Settings → Apple ID → iCloud on any device.",
                    font: .subheadline,
                    color: .secondary
                )
            }

            CronicaFormSection("Third-Party Data") {
                CronicaFormText(
                    "Anonymous crash reports may be processed by our error monitoring provider. Email support@eggerco.com to request removal. App Store purchase history is managed by Apple.",
                    font: .subheadline,
                    color: .secondary
                )

                Button("Privacy Policy") {
                    openURL(AppWebsite.privacyPolicy)
                }
#if os(macOS)
                .buttonStyle(.link)
#endif
            }

            if didDeleteData {
                CronicaFormSection("Completed") {
                    CronicaFormText(
                        "Your data has been deleted from this device. Welcome will appear again the next time you open Cronica.",
                        font: .subheadline,
                        color: .secondary
                    )
                }
            }

            Section {
                Button("Delete My Data", role: .destructive) {
                    showDeleteConfirmation = true
                }
                .disabled(isDeleting)
            } footer: {
                CronicaFormFooter("This permanently removes your personal data from Cronica on this device. It cannot be undone.")
            }
        }
        .cronicaNavigationTitle("Privacy & Data", displayMode: .inline)
        .cronicaSettingsForm()
        .overlay {
            if isDeleting {
                ProgressView("Deleting your data…")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .confirmationDialog(
            "Delete My Data?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete My Data", role: .destructive) {
                Task { await performDeletion() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This permanently removes your watchlist, lists, progress, notifications, calendar events, and preferences from this device.")
        }
        .alert("Deletion Failed", isPresented: Binding(
            get: { deletionError != nil },
            set: { if !$0 { deletionError = nil } }
        )) {
            Button("OK", role: .cancel) { deletionError = nil }
        } message: {
            Text(deletionError ?? "")
        }
    }

    @MainActor
    private func performDeletion() async {
        isDeleting = true
        defer { isDeleting = false }

        do {
            try await UserDataDeletionService.deleteAllUserData()
            didDeleteData = true
        } catch {
            deletionError = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        DataManagementSettingsView()
    }
}
