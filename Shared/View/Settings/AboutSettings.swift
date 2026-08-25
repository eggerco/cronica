//
//  AcknowledgementsSettings.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 20/12/22.
//

import SwiftUI

struct AboutSettings: View {
    @StateObject private var settings = SettingsStore.shared
    @Environment(\.openURL) private var openURL
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    let buildNumber: String = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    var body: some View {
        Form {
            Section {
                HStack(alignment: .center) {
                    VStack {
                        Image("Cronica")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100, alignment: .center)
                            .clipShape(RoundedRectangle(cornerRadius: 22.4, style: .continuous))
                            .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
                            .accessibilityHidden(true)
                            .onTapGesture(count: 3) {
                                settings.displayDeveloperSettings.toggle()
                            }
                        Text("An Egger & Co Product")
                            .fontWeight(.semibold)
                            .fontDesign(.monospaced)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .padding(.top)
                    }
                    .padding(.zero)
                }
                .frame(maxWidth: .infinity)
                .padding(.zero)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            
#if !os(tvOS)
            Section {
                
                Button("Review on the App Store") {
                    guard let writeReviewURL = URL(string: "https://apps.apple.com/app/1614950275?action=write-review") else { return }
                    openURL(writeReviewURL)
                }
#if os(macOS)
                .buttonStyle(.link)
#endif
                
                
                aboutButton(title: NSLocalizedString("X (Twitter)", comment: ""),
                            url: "https://x.com/CronicaApp")
                
                if let appUrl = URL(string: "https://apple.co/3TV9SLP") {
                    ShareLink(item: appUrl)
                        .labelStyle(.titleOnly)
#if os(macOS)
                        .buttonStyle(.link)
#endif
                }
            }
#endif
            
            Section("Content Provider") {
                aboutButton(
                    title: "The Movie Database",
                    url: "https://www.themoviedb.org"
                )
            }
            
            Section("Design") {
                aboutButton(
                    title: NSLocalizedString("Icon Designer", comment: ""),
                    subtitle: "Akhmad",
                    url: "https://www.fiverr.com/akhmad437"
                )
            }
            
            Section("Translation") {
                aboutButton(title: String(localized: "German"),
                            subtitle: "Simon Boer",
                            url: "https://twitter.com/SimonBoer29")
                aboutButton(title: String(localized: "Spanish"),
                            subtitle: "Luis Felipe Lerma Alvarez",
                            url: "https://www.instagram.com/lerma_alvarez")
                aboutButton(title: String(localized: "Slovak"),
                            subtitle: "Tomáš Švec", url: "mailto:svec.tomas@gmail.com")
                aboutButton(title: String(localized: "French"),
                            subtitle: "Pierre Quéré", url: "")
                aboutButton(title: String(localized: "Italian"),
                            subtitle: "Kevin Manca", url: "http://github.com/kevinm6")
            }
            
            Section("Libraries") {
                aboutButton(
                    title: "Nuke",
                    url: "https://github.com/kean/Nuke"
                )
                aboutButton(title: "YouTubePlayerKit",
                            url: "https://github.com/SvenTiigi/YouTubePlayerKit")
            }
            
            Section {
                if settings.displayDeveloperSettings {
                    NavigationLink("🛠️", value: SettingsScreens.developer)
                }
                CenterHorizontalView {
                    Text("Version \(appVersion ?? "") • \(buildNumber)")
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                }
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("About")
#if os(macOS)
        .formStyle(.grouped)
#endif
    }
    
    private func aboutButton(title: String, subtitle: String? = nil, url: String) -> some View {
        Button {
            guard let url = URL(string: url) else { return }
            openURL(url)
        } label: {
            buttonLabels(title: title, subtitle: subtitle)
        }
#if os(macOS)
        .buttonStyle(.link)
#endif
    }
    
    private func buttonLabels(title: String, subtitle: String?) -> some View {
        VStack(alignment: .leading) {
            Text(title)
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    AboutSettings()
}
