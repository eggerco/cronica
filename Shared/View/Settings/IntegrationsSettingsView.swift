//
//  IntegrationsSettingsView.swift
//  Cronica
//

import SwiftUI
import CronicaCore

/// Hub for optional third-party library bridges.
struct IntegrationsSettingsView: View {
    @StateObject private var settings = SettingsStore.shared

    /// TMDB primary brand blue/cyan (`#01B4E4`), solid to match SIMKL’s single-color icon treatment.
    private static let tmdbBrand = Color(red: 0x01 / 255, green: 0xB4 / 255, blue: 0xE4 / 255)

    var body: some View {
        Form {
            Section {
                Text("Connect optional services to import or sync your library with Cronica. Your Apple devices still sync through iCloud when enabled.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Library Services") {
                NavigationLink {
                    SimklSettingsView()
                } label: {
                    integrationRow(
                        title: "SIMKL",
                        subtitle: simklSubtitle,
                        systemImage: "arrow.triangle.2.circlepath",
                        fill: Color.indigo
                    )
                }

                NavigationLink {
                    TMDBAccountSettingsView()
                } label: {
                    integrationRow(
                        title: "TMDB",
                        subtitle: tmdbSubtitle,
                        systemImage: "arrow.triangle.2.circlepath",
                        fill: Self.tmdbBrand
                    )
                }
            }

            Section("Capabilities") {
                Text("SIMKL and TMDB can sync when connected. SIMKL supports incremental activity checks; TMDB re-downloads your account lists on Sync Now.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Attribution") {
                Text("SIMKL and TMDB are trademarks of their respective owners. Cronica uses these services only when you choose to connect or import.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Link("SIMKL Website", destination: URL(string: "https://simkl.com")!)
                Link("SIMKL API Rules", destination: URL(string: "https://api.simkl.org/api-rules.md")!)
                Link("TMDB Terms", destination: URL(string: "https://www.themoviedb.org/documentation/api/terms-of-use")!)
            }
        }
        .navigationTitle("Integrations")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
#if os(macOS)
        .formStyle(.grouped)
#endif
    }

    private var simklSubtitle: String {
        if !Key.isSimklConfigured {
            return String(localized: "Not configured")
        }
        if settings.isSimklConnected && SimklTokenStore.hasToken {
            if let date = settings.simklLastImportDate {
                return String(localized: "Connected") + " · " + date.formatted(date: .abbreviated, time: .shortened)
            }
            return String(localized: "Connected")
        }
        return String(localized: "Not connected")
    }

    private var tmdbSubtitle: String {
        if !Key.isConfigured {
            return String(localized: "Not configured")
        }
        if settings.isUserConnectedWithTMDb && TMDBSessionStore.hasSession {
            if let date = settings.tmdbAccountLastImportDate {
                return String(localized: "Connected") + " · " + date.formatted(date: .abbreviated, time: .shortened)
            }
            return String(localized: "Connected")
        }
        return String(localized: "Not connected")
    }

    private func integrationRow<S: ShapeStyle>(
        title: String,
        subtitle: String,
        systemImage: String,
        fill: S
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(fill)
                Image(systemName: systemImage)
                    .foregroundStyle(.white)
            }
            .frame(width: 30, height: 30)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        IntegrationsSettingsView()
    }
}
