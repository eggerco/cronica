//
//  TMDBAccountSettingsView.swift
//  Cronica
//

import SwiftUI
import CronicaCore

struct TMDBAccountSettingsView: View {
    @StateObject private var settings = SettingsStore.shared
    @State private var isConnecting = false
    @State private var isImporting = false
    @State private var importTask: Task<Void, Never>?
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
                Text("Connect your TMDB account to import your watchlist, ratings, and favorites into Cronica. Cronica already uses TMDB for catalog data; this only imports your personal lists.")
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
                Section("Last Import") {
                    LabeledContent("Added", value: "\(summary.inserted)")
                    LabeledContent("Updated", value: "\(summary.updated)")
                    LabeledContent("Skipped", value: "\(summary.skipped)")
                    LabeledContent("Failed", value: "\(summary.failed)")
                }
            }

            Section("About") {
                Text("Phase 1 is import-only. Cronica does not push watches back to TMDB or remove local titles when they leave your TMDB lists.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Link("TMDB Website", destination: URL(string: "https://www.themoviedb.org")!)
            }
        }
        .navigationTitle("TMDB Account")
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
            if isImporting {
                ProgressView {
                    VStack(spacing: 8) {
                        Text(progressPhase.isEmpty ? String(localized: "Importing…") : progressPhase)
                        if progressTotal > 0 {
                            Text("\(progressProcessed) / \(progressTotal)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Button("Cancel") { importTask?.cancel() }
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
        .onDisappear { importTask?.cancel() }
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
                LabeledContent("Last import", value: date.formatted(date: .abbreviated, time: .shortened))
            }
            Button {
                startImport()
            } label: {
                Text("Import Watchlist & Ratings")
            }
            .disabled(isImporting)
        } footer: {
            Text("Imports TMDB watchlist, ratings, and favorites. Existing Cronica titles are updated; nothing is deleted.")
        }

        Section {
            Button("Disconnect", role: .destructive) {
                importTask?.cancel()
                TMDBAccountAuthService.shared.disconnect()
                summary = nil
            }
            .disabled(isImporting)
        }
    }

#if os(iOS) || os(macOS) || os(visionOS)
    private func connect() async {
        isConnecting = true
        defer { isConnecting = false }
        do {
            try await TMDBAccountAuthService.shared.signIn()
            startImport()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
#endif

    private func startImport() {
        importTask?.cancel()
        isImporting = true
        progressPhase = ""
        progressProcessed = 0
        progressTotal = 0
        importTask = Task {
            defer {
                isImporting = false
                importTask = nil
            }
            do {
                summary = try await TMDBAccountImportService.importLibrary { value in
                    progressPhase = value.phase
                    progressProcessed = value.processed
                    progressTotal = value.total
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
