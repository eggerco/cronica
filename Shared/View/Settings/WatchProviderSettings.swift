//
//  WatchProviderSettings.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 14/06/23.
//

import SwiftUI
import NukeUI

struct WatchProviderSettings: View {
    @StateObject private var store = SettingsStore.shared
    @StateObject private var settings = SettingsStore.shared
    @State private var providers = [WatchProviderContent]()
    @State private var isLoading = true
    var body: some View {
        Form {
            Section {
                Picker(selection: $store.watchRegion) {
                    ForEach(AppContentRegion.allCases.sorted { $0.localizableTitle < $1.localizableTitle}) { region in
                        Text(region.localizableTitle)
                            .tag(region)
                    }
                } label: {
                    VStack(alignment: .leading) {
                        Text("Region")
                        Text("The app will adapt watch providers based on your region")
                            .foregroundStyle(.secondary)
                    }
                }
                .onChange(of: store.watchRegion) { 
                    if !store.selectedWatchProviders.isEmpty { store.selectedWatchProviders = "" }
                }
                .pickerStyle(.menu)
            }
#if !os(tvOS)
            Section {
                Toggle(isOn: $store.isWatchProviderEnabled) {
					Text("Watch Providers")
					Text("See in what platforms the content is available on.")
                }
                Toggle(isOn: $settings.isSelectedWatchProviderEnabled) {
                    Text("Preferred Streaming Services")
                    Text("Only show 'Watch Provider' if the title is available on one of your preferred services")
                }
                if settings.isSelectedWatchProviderEnabled {
                    Section {
                        if providers.isEmpty, !isLoading {
                            SimpleUnavailableView()
                        } else if providers.isEmpty, isLoading {
                            ProgressView()
                        } else {
                            List(providers, id: \.itemID) { item in
                                WatchProviderItemSelector(item: item)
                            }
                        }
                    }
                }
                
            }
#endif
#if os(iOS)
            languageButton
#endif
        }
        .navigationTitle("Watch Provider Settings")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .scrollBounceBehavior(.basedOnSize, axes: .vertical)
#elseif os(macOS)
        .formStyle(.grouped)
#endif
        .onChange(of: settings.isSelectedWatchProviderEnabled) { checkStatus() }
        .onAppear(perform: load)
    }
    
#if os(iOS)
    private var languageButton: some View {
        Button("Change app language") {
            Task {
                // Create the URL that deep links to your app's custom settings.
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    // Ask the system to open that URL.
                    await UIApplication.shared.open(url)
                }
            }
        }
    }
#endif
}

#Preview {
    WatchProviderSettings()
}

extension WatchProviderSettings {
    private func load() {
        if !settings.isWatchProviderEnabled { return }
        Task {
            if !isLoading { return }
            if providers.isEmpty {
                do {
                    let network = NetworkService.shared
                    let providers = try await network.fetchWatchProviderServices(for: .movie, region: SettingsStore.shared.watchRegion.rawValue)
                    var result = Set<WatchProviderContent>()
                    for item in providers.results {
                        if !result.contains(where: { $0.itemId == item.itemId }) {
                            result.insert(item)
                        }
                    }
                    self.providers.append(contentsOf: result.sorted { $0.providerTitle < $1.providerTitle})
                    withAnimation { isLoading = false }
                } catch {
                    if Task.isCancelled { return }
                    CronicaTelemetry.shared.handleMessage(error.localizedDescription,
                                                          for: "WatchProviderSelectorSetting.load.failed")
                }
            }
        }
    }
    
    private func checkStatus() {
        if settings.isSelectedWatchProviderEnabled {
            load()
        } else {
            settings.selectedWatchProviders = ""
        }
    }
}

private struct WatchProviderItemSelector: View {
    let item: WatchProviderContent
    @StateObject private var settings = SettingsStore.shared
    @State private var isSelected = false
    var body: some View {
        HStack {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? SettingsStore.shared.appTheme.color : nil)
                .fontWeight(.semibold)
                .padding(.trailing)
            LazyImage(url: item.providerImage) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Rectangle().fill(.gray.gradient)
                }
            }
                .frame(width: 40, height: 40, alignment: .center)
                .clipShape(RoundedRectangle(cornerRadius: CronicaDesign.Radius.compact, style: .continuous))
                .accessibilityHidden(true)
            Text(item.providerTitle)
        }
        .onTapGesture {
            if settings.selectedWatchProviders.contains(item.itemID) {
                let selected = settings.selectedWatchProviders.replacingOccurrences(of: item.itemID, with: "")
                settings.selectedWatchProviders = selected
            } else {
                settings.selectedWatchProviders.append(item.itemID)
            }
            HapticManager.shared.selectionHaptic()
        }
        .task(id: settings.selectedWatchProviders) {
            if settings.selectedWatchProviders.contains(item.itemID)  {
                if !isSelected {
                    withAnimation { isSelected = true }
                }
            } else {
                if isSelected {
                    withAnimation { isSelected = false }
                }
            }
        }
    }
}
