//
//  SimklSettingsView.swift
//  Cronica
//

import SwiftUI
import CronicaCore

struct SimklSettingsView: View {
    @StateObject private var settings = SettingsStore.shared
    @State private var isConnecting = false
    @State private var isSyncing = false
    @State private var isLoadingStats = false
    @State private var isLoadingPlaybacks = false
    @State private var syncTask: Task<Void, Never>?
    @State private var errorMessage: String?
    @State private var summary: SimklImportSummary?
    @State private var stats: SimklUserStats?
    @State private var playbacks: [SimklPlaybackEntry] = []
    @State private var progressPhase = ""
    @State private var progressProcessed = 0
    @State private var progressTotal = 0
#if os(tvOS)
    @State private var pinCode: String?
    @State private var pinTask: Task<Void, Never>?
#endif

    private var isConfigured: Bool { Key.isSimklConfigured }
    private var isConnected: Bool { settings.isSimklConnected && SimklTokenStore.hasToken }

    var body: some View {
        Form {
            Section {
                Text("Connect an optional SIMKL account to sync your watchlist with Cronica. CloudKit still syncs your Apple devices.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if !isConfigured {
                Section {
                    Text("SIMKL is not configured for this build. Add SIMKL_CLIENT_ID in Secrets.xcconfig.")
                        .foregroundStyle(.secondary)
                }
            } else if isConnected {
                connectedSection
                statsSection
                playbackSection
            } else {
                disconnectedSection
            }

            if let summary {
                Section("Last Sync") {
                    if summary.unchanged {
                        Text("Already up to date")
                            .foregroundStyle(.secondary)
                    } else {
                        LabeledContent("Added", value: "\(summary.inserted)")
                        LabeledContent("Updated", value: "\(summary.updated)")
                        LabeledContent("Skipped", value: "\(summary.skipped)")
                        LabeledContent("Failed", value: "\(summary.failed)")
                        if summary.removedOnSimkl > 0 {
                            LabeledContent("Removed on SIMKL", value: "\(summary.removedOnSimkl)")
                            Text("Titles removed on SIMKL stay in Cronica. Delete them here if you no longer want them.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("About SIMKL") {
                Link("SIMKL Website", destination: URL(string: "https://simkl.com")!)
                Link("SIMKL API", destination: URL(string: "https://api.simkl.org")!)
            }
        }
        .navigationTitle("SIMKL")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
#if os(macOS)
        .formStyle(.grouped)
#endif
        .alert("SIMKL", isPresented: Binding(
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
                        Button("Cancel") {
                            syncTask?.cancel()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .onAppear {
            settings.isSimklConnected = SimklTokenStore.hasToken
        }
        .onDisappear {
#if os(tvOS)
            pinTask?.cancel()
#endif
            syncTask?.cancel()
        }
    }

    @ViewBuilder
    private var disconnectedSection: some View {
        Section {
#if os(tvOS)
            if let pinCode {
                Text("Enter this code at simkl.com/pin")
                    .foregroundStyle(.secondary)
                Text(pinCode)
                    .font(.largeTitle.monospaced())
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                Button("Connect with SIMKL") {
                    Task { await connectPIN() }
                }
                .disabled(isConnecting)
            }
#else
            Button {
                Task { await connectPKCE() }
            } label: {
                if isConnecting {
                    ProgressView()
                } else {
                    Text("Connect with SIMKL")
                }
            }
            .disabled(isConnecting)
#endif
        } footer: {
            Text("Sign-in opens SIMKL in a secure browser session. Cronica never stores your SIMKL password.")
        }
    }

    @ViewBuilder
    private var connectedSection: some View {
        Section {
            Label("Connected", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
            if !settings.simklAccountName.isEmpty {
                LabeledContent("Account", value: settings.simklAccountName)
            }
            if let date = settings.simklLastImportDate {
                LabeledContent("Last sync", value: date.formatted(date: .abbreviated, time: .shortened))
            }
            Button {
                startSync(full: false)
            } label: {
                Text("Sync Now")
            }
            .disabled(isSyncing)
            Button {
                startSync(full: true)
            } label: {
                Text("Full Re-import")
            }
            .disabled(isSyncing)
        } footer: {
            Text("Sync checks SIMKL for changes since your last pull. Full re-import downloads your entire library again.")
        }

#if !os(tvOS)
        Section {
            Toggle("Push watches to SIMKL", isOn: $settings.simklPushEnabled)
        } footer: {
            Text("When enabled, watches, ratings, archive, and removals in Cronica are queued and sent to SIMKL. Off by default.")
        }
#endif

        Section {
            Button("Disconnect", role: .destructive) {
#if os(tvOS)
                pinTask?.cancel()
                pinCode = nil
#endif
                syncTask?.cancel()
                SimklAuthService.shared.disconnect()
                summary = nil
                stats = nil
                playbacks = []
            }
            .disabled(isSyncing)
        }
    }

    @ViewBuilder
    private var statsSection: some View {
        Section {
            if let stats {
                LabeledContent("Total watched", value: stats.totalHoursText)
                if let movies = stats.movies?.completed?.count {
                    LabeledContent("Movies completed", value: "\(movies)")
                }
                if let shows = stats.tv?.completed?.count {
                    LabeledContent("Shows completed", value: "\(shows)")
                }
                if let anime = stats.anime?.completed?.count {
                    LabeledContent("Anime completed", value: "\(anime)")
                }
                if let week = stats.watchedLastWeek?.totalMins {
                    LabeledContent("Last 7 days", value: Self.minutesLabel(week))
                }
                if let date = settings.simklLastStatsFetchDate {
                    Text("Fetched \(date.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Button {
                Task { await loadStats() }
            } label: {
                if isLoadingStats {
                    ProgressView()
                } else {
                    Text(stats == nil ? "Load Stats" : "Refresh Stats")
                }
            }
            .disabled(isLoadingStats || isSyncing)
        } header: {
            Text("Your SIMKL Stats")
        } footer: {
            Text("Stats are computed live on SIMKL and are expensive. Cronica only loads them when you tap this button.")
        }
    }

    @ViewBuilder
    private var playbackSection: some View {
        Section {
            if playbacks.isEmpty {
                Text("No paused playbacks.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(playbacks) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.title)
                        Text("\(entry.progressPercent)%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Button {
                Task { await loadPlaybacks() }
            } label: {
                if isLoadingPlaybacks {
                    ProgressView()
                } else {
                    Text(playbacks.isEmpty ? "Load Playbacks" : "Refresh Playbacks")
                }
            }
            .disabled(isLoadingPlaybacks || isSyncing)
        } header: {
            Text("Paused on SIMKL")
        } footer: {
            Text("Shows titles paused on other SIMKL apps. Cronica does not run a full media player, so live start/pause scrobbling is not used.")
        }
    }

#if os(iOS) || os(macOS) || os(visionOS)
    private func connectPKCE() async {
        isConnecting = true
        defer { isConnecting = false }
        do {
            try await SimklAuthService.shared.signInWithPKCE()
            _ = try? await SimklAccountService.ensureAccountID()
            startSync(full: settings.simklActivitiesAll.isEmpty)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
#endif

#if os(tvOS)
    private func connectPIN() async {
        isConnecting = true
        defer { isConnecting = false }
        do {
            let session = try await SimklAuthService.shared.beginPINSignIn()
            pinCode = session.userCode
            pinTask?.cancel()
            pinTask = Task {
                do {
                    try await SimklAuthService.shared.pollPIN(
                        userCode: session.userCode,
                        expiresIn: session.expiresIn,
                        interval: session.interval
                    )
                    pinCode = nil
                    _ = try? await SimklAccountService.ensureAccountID()
                    startSync(full: settings.simklActivitiesAll.isEmpty)
                } catch is CancellationError {
                    // ignored
                } catch {
                    errorMessage = error.localizedDescription
                    pinCode = nil
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
#endif

    private func startSync(full: Bool) {
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
                let progress: @MainActor (SimklSyncService.Progress) -> Void = { value in
                    progressPhase = value.phase
                    progressProcessed = value.processed
                    progressTotal = value.total
                }
                if full {
                    summary = try await SimklSyncService.fullImport(progress: progress)
                } else {
                    summary = try await SimklSyncService.incrementalSync(ignoreThrottle: true, progress: progress)
                }
                if settings.simklPushEnabled {
                    await SimklPushService.shared.flush()
                }
            } catch is CancellationError {
                // User cancelled.
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func loadStats() async {
        isLoadingStats = true
        defer { isLoadingStats = false }
        do {
            stats = try await SimklAccountService.loadStats()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadPlaybacks() async {
        isLoadingPlaybacks = true
        defer { isLoadingPlaybacks = false }
        do {
            playbacks = try await SimklAccountService.loadPlaybacks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private static func minutesLabel(_ mins: Int) -> String {
        let hours = mins / 60
        let rem = mins % 60
        if hours == 0 { return String(localized: "\(mins) min") }
        if rem == 0 { return String(localized: "\(hours) hr") }
        return String(localized: "\(hours) hr \(rem) min")
    }
}

#Preview {
    NavigationStack {
        SimklSettingsView()
    }
}
