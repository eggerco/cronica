//
//  TMDBAccountSettingsView.swift
//  Cronica
//

import SwiftUI
import CronicaCore

struct TMDBAccountSettingsView: View {
    @StateObject private var settings = SettingsStore.shared
    @State private var isConnecting = false
    @State private var isWorking = false
    @State private var workTask: Task<Void, Never>?
    @State private var errorMessage: String?
    @State private var summary: LibraryImportSummary?
    @State private var uploadSummary: TMDBPushService.UploadSummary?
    @State private var progressPhase = ""
    @State private var progressProcessed = 0
    @State private var progressTotal = 0

    private var isConfigured: Bool { Key.isConfigured }
    private var isConnected: Bool { settings.isUserConnectedWithTMDb && TMDBSessionStore.hasSession }

    var body: some View {
        Form {
            Section {
                Text("Connect an optional TMDB account to import watchlist, ratings, and favorites into Cronica. Uploading Cronica titles to TMDB is separate and off by default. CloudKit still syncs your Apple devices.")
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

            if let uploadSummary {
                Section("Last Upload") {
                    LabeledContent("Queued", value: "\(uploadSummary.queued)")
                    LabeledContent("Sent", value: "\(uploadSummary.sent)")
                    if uploadSummary.remaining > 0 {
                        LabeledContent("Remaining", value: "\(uploadSummary.remaining)")
                    }
                }
            }

            Section("About") {
                Text("Import from TMDB never uploads your Cronica library. Push / Upload sends watchlist, favorites, and ratings only — TMDB has no watched-history API. Titles removed on TMDB stay in Cronica.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                NavigationLink("Can't load titles from TMDB?") {
                    TMDBUnavailableHelpView()
                }
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
            if isWorking {
                ProgressView {
                    VStack(spacing: 8) {
                        Text(progressPhase.isEmpty ? String(localized: "Working…") : progressPhase)
                        if progressTotal > 0 {
                            Text(String(format: String(localized: "%lld / %lld"), progressProcessed, progressTotal))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Button("Cancel") { workTask?.cancel() }
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
        .onDisappear { workTask?.cancel() }
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
            Text("Sign-in opens TMDB in a secure browser session. Cronica stores a session token on this device only — connect again on each device. Connecting imports from TMDB; it does not upload your Cronica library.")
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
                Text("Import from TMDB")
            }
            .disabled(isWorking)
        } footer: {
            Text("Downloads your TMDB watchlist, ratings, and favorites into Cronica. Existing Cronica titles are updated; nothing is deleted. This does not upload Cronica titles to TMDB.")
        }

#if !os(tvOS)
        Section {
            Toggle("Push changes to TMDB", isOn: $settings.tmdbPushEnabled)
            Button {
                startUpload()
            } label: {
                Text("Upload Library to TMDB")
            }
            .disabled(isWorking || !settings.tmdbPushEnabled)
        } footer: {
            Text("Push queues future watchlist, favorite, and rating changes. Upload Library sends your current Cronica library once. Marking watched removes the title from the TMDB watchlist (TMDB has no watched-history API). Off by default.")
        }
#endif

        Section {
            Button("Disconnect", role: .destructive) {
                workTask?.cancel()
                TMDBAccountAuthService.shared.disconnect()
                summary = nil
                uploadSummary = nil
            }
            .disabled(isWorking)
        }
    }

#if os(iOS) || os(macOS) || os(visionOS)
    private func connect() async {
        isConnecting = true
        defer { isConnecting = false }
        do {
            try await TMDBAccountAuthService.shared.signIn()
            startImport()
        } catch is CancellationError {
            return
        } catch let error as LibraryImportError {
            if case .cancelled = error { return }
            errorMessage = TMDBConnectionFailure.userFacingMessage(for: error)
        } catch {
            errorMessage = TMDBConnectionFailure.userFacingMessage(for: error)
        }
    }
#endif

    private func startImport() {
        workTask?.cancel()
        isWorking = true
        progressPhase = ""
        progressProcessed = 0
        progressTotal = 0
        workTask = Task {
            defer {
                isWorking = false
                workTask = nil
            }
            do {
                summary = try await TMDBSyncService.syncNow { value in
                    progressPhase = value.phase
                    progressProcessed = value.processed
                    progressTotal = value.total
                }
                if settings.tmdbPushEnabled {
                    _ = await TMDBPushService.shared.flush()
                }
            } catch is CancellationError {
                // ignored
            } catch {
                errorMessage = TMDBConnectionFailure.userFacingMessage(for: error)
            }
        }
    }

    private func startUpload() {
        workTask?.cancel()
        isWorking = true
        progressPhase = ""
        progressProcessed = 0
        progressTotal = 0
        workTask = Task {
            defer {
                isWorking = false
                workTask = nil
            }
            do {
                uploadSummary = try await TMDBPushService.shared.uploadCurrentLibrary { value in
                    progressPhase = value.phase
                    progressProcessed = value.processed
                    progressTotal = value.total
                }
            } catch is CancellationError {
                // ignored
            } catch {
                errorMessage = TMDBConnectionFailure.userFacingMessage(for: error)
            }
        }
    }
}

#Preview {
    NavigationStack {
        TMDBAccountSettingsView()
    }
}
