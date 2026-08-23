//
//  WelcomeView.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 18/03/22.
//

import SwiftUI
#if !os(macOS)
private enum WelcomeURLs {
    static let privacyPolicy = URL(string: "https://www.oncronica.com/privacy")
}

/// Onboard experience.
struct WelcomeView: View {
    @AppStorage("showOnboarding") var displayOnboard = true
    @State private var showPolicy = false
    var body: some View {
        VStack(alignment: .leading) {
            CenterHorizontalView {
                HStack {
                    Image("Cronica")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 90, height: 90, alignment: .center)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(radius: 5)
                        .padding(.leading)
                    VStack(alignment: .leading) {
                        Text("Cronica")
                            .font(.title)
                            .fontWeight(.bold)
                            .fontDesign(.rounded)
                        Text("An Egger & Co Product")
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .fontDesign(.rounded)
                            .padding(.trailing)
                    }
                    .padding(.leading, 6)
                }
            }
            .padding([.top, .bottom])
            ScrollView {
                informationContainerView
            }
            .padding(.horizontal)
            Spacer()
            HStack {
                Spacer()
                Button("Continue") {
                    withAnimation {
                        displayOnboard.toggle()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.blue.gradient)
#if os(iOS) || os(macOS)
                .controlSize(.large)
#endif
                .padding([.leading, .vertical])
                Button {
#if os(macOS)
                    if let privacyPolicy = WelcomeURLs.privacyPolicy {
                        NSWorkspace.shared.open(privacyPolicy)
                    }
#else
                    showPolicy.toggle()
#endif
                } label: {
                    Text("Privacy Policy")
                        .lineLimit(1)
                }
                .padding([.horizontal, .vertical])
#if os(iOS) || os(macOS)
                .controlSize(.large)
#endif
#if os(macOS)
                .buttonStyle(.link)
#else
                .buttonStyle(.bordered)
#endif
                Spacer()
            }
            .padding()
        }
        .interactiveDismissDisabled(true)
#if os(iOS)
        .fullScreenCover(isPresented: $showPolicy) {
            if let privacyPolicy = WelcomeURLs.privacyPolicy {
                SFSafariViewWrapper(url: privacyPolicy)
            }
        }
#endif
    }
    
    private var informationContainerView: some View {
        VStack(alignment: .leading) {
            informationItem(
                title: NSLocalizedString("Your Watchlist", comment: ""),
                subtitle: NSLocalizedString("Add everything you want, the Watchlist automatically organizes it for you.", comment: ""),
                imageName: "rectangle.stack.fill",
                imageTint: .purple
            )
            
            informationItem(
                title: NSLocalizedString("Always Synced", comment: ""),
                subtitle: NSLocalizedString("Your Watchlist is always in sync with your Apple Watch, iPad, Mac, and Apple TV.", comment: ""),
                imageName: "icloud.fill"
            )
            
            informationItem(
                title: NSLocalizedString("Track your episodes", comment: ""),
                subtitle: NSLocalizedString("Keep track of every episode you've watched.", comment: ""),
                imageName: "rectangle.fill.badge.checkmark",
                imageTint: .green
            )
            
            informationItem(
                title: NSLocalizedString("Never miss out", comment: ""),
                subtitle: NSLocalizedString("Get notifications about the newest releases.", comment: ""),
                imageName: "bell.fill",
                imageTint: .orange
            )
            
        }
    }
    
    private func informationItem(
        title: String,
        subtitle: String,
        imageName: String,
        imageTint: Color = .blue
    ) -> some View {
        HStack(alignment: .center) {
            Image(systemName: imageName)
                .font(.largeTitle)
                .frame(width: 60)
                .accessibility(hidden: true)
                .foregroundColor(imageTint)
            
            VStack(alignment: .leading) {
                Text(NSLocalizedString(title, comment: ""))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .accessibility(addTraits: .isHeader)
                    .fontDesign(.rounded)
                
                Text(NSLocalizedString(subtitle, comment: ""))
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .fontDesign(.rounded)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.leading, 6)
            .padding([.top, .bottom], 8)
        }
        .padding(.top)
    }
}

#Preview {
    WelcomeView()
}
#endif
