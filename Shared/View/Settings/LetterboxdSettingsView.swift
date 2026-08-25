//
//  LetterboxdSettingsView.swift
//  Cronica
//

import SwiftUI
import UniformTypeIdentifiers

struct LetterboxdSettingsView: View {
    @StateObject private var settings = SettingsStore.shared
    @State private var isImporting = false
    @State private var showFilePicker = false
    @State private var importTask: Task<Void, Never>?
    @State private var errorMessage: String?
    @State private var summary: LibraryImportSummary?
    @State private var progressPhase = ""
    @State private var progressProcessed = 0
    @State private var progressTotal = 0

    var body: some View {
        Form {
            Section {
                Text("Import a Letterboxd CSV export into Cronica. This is a one-time import — Letterboxd’s API is invitation-only, so Cronica does not offer live sync.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("How to export") {
                Text("1. On letterboxd.com, open Settings → Data → Export.\n2. Unzip the download.\n3. Import watchlist.csv, watched.csv, and/or ratings.csv (one file at a time).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Link("Open Letterboxd Data settings", destination: URL(string: "https://letterboxd.com/settings/data/")!)
            }

#if os(iOS) || os(macOS) || os(visionOS)
            Section {
                if let date = settings.letterboxdLastImportDate {
                    LabeledContent("Last import", value: date.formatted(date: .abbreviated, time: .shortened))
                }
                Button {
                    showFilePicker = true
                } label: {
                    Text("Import CSV…")
                }
                .disabled(isImporting)
            } footer: {
                Text("Letterboxd exports don’t include TMDB IDs. Cronica matches films by title and year and skips ambiguous results. TV titles may be skipped.")
            }
#else
            Section {
                Text("CSV import is available on iPhone, iPad, and Mac.")
                    .foregroundStyle(.secondary)
            }
#endif

            if let summary {
                Section("Last Import") {
                    LabeledContent("Added", value: "\(summary.inserted)")
                    LabeledContent("Updated", value: "\(summary.updated)")
                    LabeledContent("Skipped", value: "\(summary.skipped)")
                    LabeledContent("Failed", value: "\(summary.failed)")
                }
            }

            Section("Limitations") {
                Text("No OAuth or two-way sync. Importing never deletes titles from Cronica.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Letterboxd")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
#if os(macOS)
        .formStyle(.grouped)
#endif
        .alert("Letterboxd", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
#if os(iOS) || os(macOS) || os(visionOS)
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.commaSeparatedText, .plainText, .data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                startImport(url: url)
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
#endif
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
        .onDisappear { importTask?.cancel() }
    }

#if os(iOS) || os(macOS) || os(visionOS)
    private func startImport(url: URL) {
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
                let accessed = url.startAccessingSecurityScopedResource()
                defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                let data = try Data(contentsOf: url)
                summary = try await LibraryImportService.importCSV(
                    data: data,
                    source: .letterboxd,
                    filename: url.lastPathComponent
                ) { value in
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
#endif
}

#Preview {
    NavigationStack {
        LetterboxdSettingsView()
    }
}
