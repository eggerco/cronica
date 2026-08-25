//
//  TMDBAccountSettingsView.swift
//  Cronica
//

import SwiftUI
import CronicaCore

struct TMDBAccountSettingsView: View {
    @StateObject private var settings = SettingsStore.shared
    @State private var isConnecting = false
    @State private var isSyncing = false
    @State private var syncTask: Task<Void, Never>?
    @State private var errorMessage: String?
    @State private var summary: LibraryImportSummary?
    @State private var progressPhase = ""
    @State private var progressProcessed = 0
    @State private var progressTotal = 0

    private var isConfigured: Bool { Key.isConfigured }
    private var isConnected: Bool { settings.isUserConnectedWithTMDb && TMDBSessionStore.hasSession }

    var body: some View {
        Form {
            Section {
                Text("Connect an optional TMDB account to sync your watchlist, ratings, and favorites with Cronica. Cronica already uses TMDB for catalog data; CloudKit still syncs your Apple devices.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if !isConfigured {
                Section {
                    Text("TMDB is not configured for this build. Add TMDB_API_KEY in Secrets.xcconfig.")
                        .foregroundStyle(.secondary)
                }
            } else if isConnected {
                connectedSection
            } else {
                disconnectedSection
            }

            if let summary {
                Section("Last Sync") {
                    LabeledContent("Added", value: "\(summary.inserted)")
                    LabeledContent("Updated", value: "\(summary.updated)")
                    LabeledContent("Skipped", value: "\(summary.skipped)")
                    LabeledContent("Failed", value: "\(summary.failed)")
                }
            }

            Section("About") {
                Text("TMDB has no activity feed or watched-history API. Sync re-downloads your account lists. Titles removed on TMDB stay in Cronica. Live scrobbling is not available.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Link("TMDB Website", destination: URL(string: "https://www.themoviedb.org")!)
                Link("TMDB API Terms", destination: URL(string: "https://www.themoviedb.org/documentation/api/terms-of-use")!)
            }
        }
        .navigationTitle("TMDB")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
#if os(macOS)
        .formStyle(.grouped)
#endif
        .alert("TMDB", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .overlay {
            if isSyncing {
                ProgressView {
                    VStack(spacing: 8) {
                        Text(progressPhase.isEmpty ? String(localized: "Syncing…") : progressPhase)
                        if progressTotal > 0 {
                            Text("\(progressProcessed) / \(progressTotal)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Button("Cancel") { syncTask?.cancel() }
                            .buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .onAppear {
            settings.isUserConnectedWithTMDb = TMDBSessionStore.hasSession
        }
        .onDisappear { syncTask?.cancel() }
    }

    @ViewBuilder
    private var disconnectedSection: some View {
        Section {
#if os(iOS) || os(macOS) || os(visionOS)
            Button {
                Task { await connect() }
            } label: {
                if isConnecting {
                    ProgressView()
                } else {
                    Text("Connect with TMDB")
                }
            }
            .disabled(isConnecting)
#else
            Text("Connect a TMDB account from iPhone, iPad, or Mac.")
                .foregroundStyle(.secondary)
#endif
        } footer: {
            Text("Sign-in opens TMDB in a secure browser session. Cronica stores a session token on this device only.")
        }
    }

    @ViewBuilder
    private var connectedSection: some View {
        Section {
            Label("Connected", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
            if !settings.tmdbAccountName.isEmpty {
                LabeledContent("Account", value: settings.tmdbAccountName)
            }
            if let date = settings.tmdbAccountLastImportDate {
                LabeledContent("Last sync", value: date.formatted(date: .abbreviated, time: .shortened))
            }
            Button {
                startSync()
            } label: {
                Text("Sync Now")
            }
            .disabled(isSyncing)
        } footer: {
            Text("Downloads your TMDB watchlist, ratings, and favorites. Existing Cronica titles are updated; nothing is deleted.")
        }

#if !os(tvOS)
        Section {
            Toggle("Push changes to TMDB", isOn: $settings.tmdbPushEnabled)
        } footer: {
            Text("When enabled, watchlist, favorites, and ratings in Cronica are queued and sent to TMDB. Marking watched removes the title from your TMDB watchlist (TMDB has no watched-history API). Off by default.")
        }
#endif

        Section {
            Button("Disconnect", role: .destructive) {
                syncTask?.cancel()
                TMDBAccountAuthService.shared.disconnect()
                summary = nil
            }
            .disabled(isSyncing)
        }
    }

#if os(iOS) || os(macOS) || os(visionOS)
    private func connect() async {
        isConnecting = true
        defer { isConnecting = false }
        do {
            try await TMDBAccountAuthService.shared.signIn()
            startSync()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
#endif

    private func startSync() {
        syncTask?.cancel()
        isSyncing = true
        progressPhase = ""
        progressProcessed = 0
        progressTotal = 0
        syncTask = Task {
            defer {
                isSyncing = false
                syncTask = nil
            }
            do {
                summary = try await TMDBSyncService.syncNow { value in
                    progressPhase = value.phase
                    progressProcessed = value.processed
                    progressTotal = value.total
                }
                if settings.tmdbPushEnabled {
                    await TMDBPushService.shared.flush()
                }
            } catch is CancellationError {
                // ignored
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    NavigationStack {
        TMDBAccountSettingsView()
    }
}
