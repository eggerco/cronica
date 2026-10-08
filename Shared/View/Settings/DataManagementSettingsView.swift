//
//  DataManagementSettingsView.swift
//  Cronica
//

import SwiftUI

struct DataManagementSettingsView: View {
    @Environment(\.openURL) private var openURL
    @StateObject private var cloudKitStatus = CloudKitSyncStatusStore.shared
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var deletionError: String?
    @State private var didDeleteData = false

    var body: some View {
        Form {
            Section {
                Button {
                    openURL(AppWebsite.privacyPolicy)
                } label: {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }
#if os(macOS)
                .buttonStyle(.link)
#endif
            }

            Section("Your Data") {
                Text("Cronica does not require accounts. Your watchlist, ratings, notes, and preferences are stored on this device and, if enabled, in your private iCloud account. Optional integrations (SIMKL, TMDB) can be connected for sync.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("What Gets Deleted") {
                Label("Watchlist items and custom lists", systemImage: "rectangle.on.rectangle")
                Label("Episode progress, ratings, and notes", systemImage: "note.text")
                Label("Scheduled notifications", systemImage: "bell")
#if !os(tvOS) && !os(watchOS)
                Label("Cronica calendar and release events", systemImage: "calendar")
#endif
                Label("App preferences and filters", systemImage: "slider.horizontal.3")
                Label("SIMKL and TMDB sign-in tokens (if connected)", systemImage: "arrow.triangle.2.circlepath")
            }

            Section("iCloud Sync") {
                LabeledContent("Status", value: cloudKitStatus.statusTitle)
                Text(cloudKitStatus.statusDetail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Refresh Status") {
                    Task { await cloudKitStatus.refreshAccountStatus() }
                }
                Text("Watchlist sync uses Apple iCloud automatically. Use the same Apple ID on each device, keep Cronica enabled under iCloud, and leave the app open on Wi‑Fi for a few minutes after adding titles. Refreshing Home only reloads the online catalog — it does not sync devices.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .onAppear { cloudKitStatus.startIfNeeded() }

            Section("Third-Party Data") {
                Text("Anonymous crash reports may be processed by our error monitoring provider. Email support@cronica.watch to request removal.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if didDeleteData {
                Section("Completed") {
                    Text("Your data has been deleted from this device. Welcome will appear again the next time you open Cronica.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button("Delete My Data", role: .destructive) {
                    showDeleteConfirmation = true
                }
                .disabled(isDeleting)
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
                    Text("This permanently removes your watchlist, lists, progress, notifications, calendar events, preferences, and any SIMKL or TMDB sign-in from this device.")
                }
            } footer: {
                Text("This permanently removes your personal data from Cronica on this device. It cannot be undone.")
            }
        }
        .navigationTitle(String(localized: "Privacy & Data"))
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
#if os(macOS)
        .formStyle(.grouped)
#endif
        .accessibilityIdentifier("Privacy & Data View")
        .overlay {
            if isDeleting {
                ProgressView("Deleting your data…")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
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
