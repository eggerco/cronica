//
//  WelcomeView.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 18/03/22.
//

import SwiftUI
#if !os(macOS)
/// First-run onboarding aligned with Cronica brand chrome (About-style logo + accent tint).
struct WelcomeView: View {
    @AppStorage("showOnboarding") var displayOnboard = true
    @StateObject private var settings = SettingsStore.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 28) {
                        brandHeader
                            .padding(.top, 24)

                        VStack(alignment: .leading, spacing: 20) {
                            featureRow(
                                title: "Your Watchlist",
                                subtitle: "Save movies and shows — Cronica keeps them organized for you.",
                                systemImage: "rectangle.stack.fill"
                            )
                            featureRow(
                                title: "Always Synced",
                                subtitle: "Your list stays in sync across iPhone, iPad, Mac, Apple Watch, and Apple TV.",
                                systemImage: "icloud.fill"
                            )
                            featureRow(
                                title: "Track episodes",
                                subtitle: "Mark what you’ve watched and pick up right where you left off.",
                                systemImage: "rectangle.fill.badge.checkmark"
                            )
                            featureRow(
                                title: "Never miss a release",
                                subtitle: "Get notified when new movies and episodes arrive.",
                                systemImage: "bell.fill"
                            )
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 12)
                    }
                }

                VStack(spacing: 12) {
                    Button {
                        if reduceMotion {
                            displayOnboard = false
                        } else {
                            withAnimation {
                                displayOnboard = false
                            }
                        }
                    } label: {
                        Text("Continue")
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(settings.appTheme.color)
                    .accessibilityIdentifier("Continue")

                    Button {
                        openURL(AppWebsite.privacyPolicy)
                    } label: {
                        Text("Privacy Policy")
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.regular)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
            .environment(\.textCase, nil)
            .background()
            .interactiveDismissDisabled(true)
            .toolbar(.hidden, for: .navigationBar)
        }
        .accessibilityIdentifier("Welcome View")
        .appTint()
        .appTheme()
    }

    private var brandHeader: some View {
        VStack(spacing: 12) {
            Image("Cronica")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 22.4, style: .continuous))
                .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
                .accessibilityHidden(true)

            Text("Cronica")
                .font(.largeTitle.weight(.bold))
                .fontDesign(.rounded)

            Text("Track what you watch. Never lose your place.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private func featureRow(title: LocalizedStringKey, subtitle: LocalizedStringKey, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(settings.appTheme.color)
                .frame(width: 36, alignment: .center)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontDesign(.rounded)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    WelcomeView()
}
#endif
