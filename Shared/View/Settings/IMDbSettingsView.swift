//
//  IMDbSettingsView.swift
//  Cronica
//

import SwiftUI
import UniformTypeIdentifiers

struct IMDbSettingsView: View {
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
                Text("Import an IMDb CSV export into Cronica. IMDb has no public library API, so Cronica uses official desktop CSV exports only — not live sync.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("How to export") {
                Text("1. On the IMDb desktop website, open Your Watchlist or Your Ratings.\n2. Use Export (⋯ menu).\n3. Import the downloaded .csv here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Link("Open IMDb", destination: URL(string: "https://www.imdb.com/")!)
            }

#if os(iOS) || os(macOS) || os(visionOS)
            Section {
                if let date = settings.imdbLastImportDate {
                    LabeledContent("Last import", value: date.formatted(date: .abbreviated, time: .shortened))
                }
                Button {
                    showFilePicker = true
                } label: {
                    Text("Import CSV…")
                }
                .disabled(isImporting)
            } footer: {
                Text("Rows resolve via TMDB’s IMDb ID lookup. Episode-only rows are skipped. Titles without a TMDB match are skipped.")
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
                Text("No OAuth or push sync. Importing never deletes titles from Cronica.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("IMDb")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
#if os(macOS)
        .formStyle(.grouped)
#endif
        .alert("IMDb", isPresented: Binding(
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
                    source: .imdb,
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
        IMDbSettingsView()
    }
}
