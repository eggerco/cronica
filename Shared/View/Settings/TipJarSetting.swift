//
//  TipJarSetting.swift
//  Cronica
//
//  Created by Alexandre Madeira on 05/01/23.
//

import SwiftUI
import StoreKit

struct TipJarSetting: View {
    @StateObject private var viewModel = StoreKitManager()
    @State private var productsLoaded = false
    @StateObject private var settings: SettingsStore = .shared
    var body: some View {
        Form {
            Section {
                if !productsLoaded { ProgressView() }
                if viewModel.hasUserPurchased || settings.hasPurchasedTipJar {
#if os(tvOS)
                    Button("Thank you for your purchase! Your support is much appreciated. 😁") { }
#else
                    Text("Thank you for your purchase! Your support is much appreciated. 😁")
#endif
                }
                ForEach(viewModel.storeProducts.sorted { $0.price < $1.price}) { item in
                    Button {
                        Task {
                            try await viewModel.purchase(item)
                        }
                    } label: {
                        TipJarItem(storeKit: viewModel, product: item)
                    }
#if os(macOS)
                    .buttonStyle(.plain)
#endif
                }
                Button("Restore Purchase") {
                    Task {
                        try? await AppStore.sync()
                    }
                }
                .disabled(!productsLoaded)
            } header: {
#if os(macOS)
                Label("Tip Jar", systemImage: "heart")
#endif
            } footer: {
                if !SettingsStore.shared.hasPurchasedTipJar {
                    Text("You can choose to contribute a small, medium, or large amount, and all proceeds will go towards improving and maintaining the app. Cronica will always remain free and ad-free, so this is purely an optional way for users to support the development of the app.")
                }
            }
        }
        .navigationTitle("Tip Jar")
        .onChange(of: viewModel.hasLoadedProducts) { _, hasLoaded in
            if hasLoaded {
                withAnimation { productsLoaded = true }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
#if os(macOS)
        .formStyle(.grouped)
#endif
    }
}

private struct TipJarItem: View {
    @ObservedObject var storeKit: StoreKitManager
    @State private var isPurchased = false
    var product: Product
    var body: some View {
        HStack {
            VStack {
                VStack(alignment: .leading) {
                    Text(product.displayName)
                    Text(product.description)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            if isPurchased {
                Image(systemName: "checkmark.circle.fill")
                    .fontWeight(.semibold)
            } else {
                Text(product.displayPrice)
                    .fontWeight(.semibold)
            }
        }
        .onChange(of: storeKit.purchasedTipJar) {
            Task {
                isPurchased = (try? await storeKit.isPurchased(product)) ?? false
            }
        }
    }
}

#Preview {
    TipJarSetting()
}
