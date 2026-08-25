//
//  IntegrationsSettingsView.swift
//  Cronica
//

import SwiftUI
import CronicaCore

/// Hub for optional third-party library bridges (SIMKL today; more later).
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
                NavigationLink(value: SettingsScreens.simkl) {
                    integrationRow(
                        title: "SIMKL",
                        subtitle: simklSubtitle,
                        systemImage: "arrow.triangle.2.circlepath",
                        color: .indigo
                    )
                }
            }

            Section("Attribution") {
                Text("SIMKL is a trademark of its respective owners. Cronica uses the SIMKL API when you choose to connect an account.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Link("SIMKL Website", destination: URL(string: "https://simkl.com")!)
                Link("SIMKL API Rules", destination: URL(string: "https://api.simkl.org/api-rules.md")!)
            }
        }
        .navigationTitle("Integrations")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
#if os(macOS)
        .formStyle(.grouped)
#endif
        .navigationDestination(for: SettingsScreens.self) { screen in
            if screen == .simkl {
                SimklSettingsView()
            }
        }
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
