//
//  FeedbackSettingsView.swift
//  Cronica
//
//  Created by Alexandre Madeira on 16/11/22.
//

import SwiftUI

struct FeedbackComposerView: View {
    @Environment(\.openURL) var openURL
    @StateObject private var settings = SettingsStore.shared
    @State private var supportEmail = SupportEmail()
    var body: some View {
        Form {
#if !os(tvOS)
            Section {
                Button("Send Email") { supportEmail.send(openURL: openURL) }
            } footer: {
                HStack {
                    VStack(alignment: .leading) {
                        Text("If you prefer, you can send an email for a faster follow-up.")
                    }
                    Spacer()
                }
            }
#if os(macOS)
            .buttonStyle(.link)
#endif
            
            Section {
                Button("X (Twitter)") {
                    guard let url = URL(string: "https://x.com/CronicaApp") else { return }
                    openURL(url)
                }
#if os(macOS)
                .buttonStyle(.link)
#endif
            } header: {
                Text("Social Media")
            } footer: {
                Text("Follow Cronica on X (Twitter) to stay updated about new features.")
            }
#endif
        }
        .navigationTitle("Feedback")
        .cronicaSettingsForm()
    }
}

#Preview {
    FeedbackComposerView()
}
