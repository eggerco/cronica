//
//  WelcomeView.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 18/03/22.
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

/// Onboard experience.
struct WelcomeView: View {
    @AppStorage("showOnboarding") var displayOnboard = true
    @State private var showPolicy = false
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL
    @StateObject private var store = SettingsStore.shared

    var body: some View {
        ZStack {
            atmosphere
            VStack(spacing: 0) {
                Spacer(minLength: CronicaDesign.Spacing.xl)
                brandBlock
                Spacer()
                VStack(spacing: CronicaDesign.Spacing.md) {
                    Text("Never miss a release.")
                        .font(CronicaDesign.Typography.sectionSubtitle())
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, CronicaDesign.Spacing.xl)
                    continueButton
                    privacyButton
                }
                .padding(.bottom, CronicaDesign.Spacing.xxl)
            }
            .padding(.horizontal, CronicaDesign.Spacing.lg)
        }
        .interactiveDismissDisabled(true)
        .onAppear {
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(CronicaDesign.Motion.standard) {
                    appeared = true
                }
            }
        }
#if os(iOS)
        .fullScreenCover(isPresented: $showPolicy) {
            SFSafariViewWrapper(url: URL(string: "https://www.oncronica.com/privacy")!)
        }
#endif
    }

    private var atmosphere: some View {
        ZStack {
            LinearGradient(
                colors: [
                    store.appTheme.color.opacity(0.35),
                    Color(white: 0.08),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    store.appTheme.color.opacity(0.28),
                    .clear
                ],
                center: .top,
                startRadius: 20,
                endRadius: 420
            )
            .ignoresSafeArea()
            .blendMode(.plusLighter)
        }
    }

    private var brandBlock: some View {
        VStack(spacing: CronicaDesign.Spacing.md) {
            Image("Cronica")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 112, height: 112)
                .clipShape(RoundedRectangle(cornerRadius: CronicaDesign.Radius.large, style: .continuous))
                .shadow(color: .black.opacity(0.35), radius: 20, x: 0, y: 12)
                .scaleEffect(appeared ? 1 : 0.92)
                .opacity(appeared ? 1 : 0)

            Text("Cronica")
                .font(CronicaDesign.Typography.brand())
                .foregroundStyle(.white)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)

            Text("Your watchlist for movies and TV — with reminders when something new drops.")
                .font(CronicaDesign.Typography.sectionSubtitle())
                .foregroundStyle(.white.opacity(0.78))
                .multilineTextAlignment(.center)
                .padding(.horizontal, CronicaDesign.Spacing.md)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
        }
    }

    private var continueButton: some View {
        Button {
            if reduceMotion {
                displayOnboard = false
            } else {
                withAnimation(CronicaDesign.Motion.gentle) {
                    displayOnboard = false
                }
            }
        } label: {
            Text("Continue")
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(store.appTheme.color)
#if os(iOS) || os(macOS)
        .controlSize(.large)
#endif
        .opacity(appeared ? 1 : 0)
    }

    private var privacyButton: some View {
        Button {
#if os(iOS)
            showPolicy.toggle()
#else
            if let url = URL(string: "https://www.oncronica.com/privacy") {
#if os(macOS)
                NSWorkspace.shared.open(url)
#else
                openURL(url)
#endif
            }
#endif
        } label: {
            Text("Privacy Policy")
                .font(CronicaDesign.Typography.caption())
        }
#if os(iOS) || os(macOS)
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
#endif
        .opacity(appeared ? 1 : 0)
    }
}

#Preview {
    WelcomeView()
}
