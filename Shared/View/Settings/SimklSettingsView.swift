//
//  SimklSettingsView.swift
//  Cronica
//

import SwiftUI
import CronicaCore

struct SimklSettingsView: View {
    @StateObject private var settings = SettingsStore.shared
    @State private var isConnecting = false
    @State private var isImporting = false
    @State private var importTask: Task<Void, Never>?
    @State private var errorMessage: String?
    @State private var summary: SimklImportSummary?
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
                Text("Connect an optional SIMKL account to import your watchlist into Cronica. CloudKit still syncs your devices.")
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
            if isImporting {
                ProgressView {
                    VStack(spacing: 8) {
                        Text(progressPhase.isEmpty ? String(localized: "Importing…") : progressPhase)
                        if progressTotal > 0 {
                            Text("\(progressProcessed) / \(progressTotal)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Button("Cancel") {
                            importTask?.cancel()
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
            importTask?.cancel()
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
            if let date = settings.simklLastImportDate {
                LabeledContent("Last import", value: date.formatted(date: .abbreviated, time: .shortened))
            }
            Button {
                startImport()
            } label: {
                Text("Import from SIMKL")
            }
            .disabled(isImporting)
            Button("Disconnect", role: .destructive) {
#if os(tvOS)
                pinTask?.cancel()
                pinCode = nil
#endif
                importTask?.cancel()
                SimklAuthService.shared.disconnect()
                summary = nil
            }
            .disabled(isImporting)
        } footer: {
            Text("Import merges into your local watchlist by TMDB ID. Existing titles are updated; items without a TMDB ID are skipped.")
        }
    }

#if os(iOS) || os(macOS) || os(visionOS)
    private func connectPKCE() async {
        isConnecting = true
        defer { isConnecting = false }
        do {
            try await SimklAuthService.shared.signInWithPKCE()
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
                summary = try await SimklImportService.importLibrary { progress in
                    progressPhase = progress.phase
                    progressProcessed = progress.processed
                    progressTotal = progress.total
                }
            } catch is CancellationError {
                // User cancelled.
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    NavigationStack {
        SimklSettingsView()
    }
}
