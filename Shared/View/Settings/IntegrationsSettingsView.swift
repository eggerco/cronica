//
//  IntegrationsSettingsView.swift
//  Cronica
//

import SwiftUI
import CronicaCore

/// Hub for optional third-party library bridges.
struct IntegrationsSettingsView: View {
    @StateObject private var settings = SettingsStore.shared

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
                        color: .indigo
                    )
                }

                NavigationLink {
                    TMDBAccountSettingsView()
                } label: {
                    integrationRow(
                        title: "TMDB Account",
                        subtitle: tmdbSubtitle,
                        systemImage: "person.crop.circle.badge.checkmark",
                        color: .green
                    )
                }

                NavigationLink {
                    LetterboxdSettingsView()
                } label: {
                    integrationRow(
                        title: "Letterboxd",
                        subtitle: letterboxdSubtitle,
                        systemImage: "film.stack",
                        color: .orange
                    )
                }

                NavigationLink {
                    IMDbSettingsView()
                } label: {
                    integrationRow(
                        title: "IMDb",
                        subtitle: imdbSubtitle,
                        systemImage: "star.square.on.square",
                        color: .yellow
                    )
                }
            }

            Section("Capabilities") {
                Text("SIMKL can sync continuously when connected. Letterboxd and IMDb are CSV import only. TMDB Account imports your personal lists after sign-in.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Attribution") {
                Text("SIMKL, Letterboxd, IMDb, and TMDB are trademarks of their respective owners. Cronica uses these services only when you choose to connect or import.")
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
            return String(localized: "Connected")
        }
        return String(localized: "Not connected")
    }

    private var tmdbSubtitle: String {
        if !Key.isConfigured {
            return String(localized: "Not configured")
        }
        if settings.isUserConnectedWithTMDb && TMDBSessionStore.hasSession {
            return String(localized: "Connected")
        }
        return String(localized: "Import account lists")
    }

    private var letterboxdSubtitle: String {
        if settings.letterboxdLastImportDate != nil {
            return String(localized: "Imported")
        }
        return String(localized: "CSV import")
    }

    private var imdbSubtitle: String {
        if settings.imdbLastImportDate != nil {
            return String(localized: "Imported")
        }
        return String(localized: "CSV import")
    }

    private func integrationRow(title: String, subtitle: String, systemImage: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(color)
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
