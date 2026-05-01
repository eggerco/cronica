//
//  OverviewBoxView.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 25/04/22.
//

import SwiftUI
#if os(iOS)
import AdmobSwiftUI
#endif

#if !os(tvOS)
/// Displays the overview of a movie, tv show, or episode.
/// It can also display biography.
struct OverviewBoxView: View {
    let overview: String?
    let title: String
    var type: MediaType = .movie
    var showAsPopover = false
    @State private var showFullText = false
    @State private var showSheet = false
    @State private var showTextOptions = true
    @State private var isTruncated = false
    @StateObject private var settings = SettingsStore.shared
#if os(iOS)
    @StateObject private var nativeViewModel = NativeAdViewModel(
        adUnitID: AdConfiguration.AdUnitID.native,
        requestInterval: AdConfiguration.nativeRefreshInterval
    )

    private var shouldShowNativeAd: Bool {
        DetailAdPolicy.shouldShowNativeAd(
            hasPurchasedTipJar: settings.hasPurchasedTipJar,
            monetizationDisabled: PreviewVideoRuntime.shouldDisableMonetization()
        )
    }
#endif

    var body: some View {
        if let overview, !overview.isEmpty {
            VStack(spacing: 12) {
                overviewBox(overview)
#if os(iOS)
                if shouldShowNativeAd {
                    NativeAdView(nativeViewModel: nativeViewModel, style: .largeBanner)
                        .frame(height: 320)
                        .onAppear {
                            nativeViewModel.refreshAd()
                        }
                }
#endif
            }
        }
    }

    private func overviewBox(_ overview: String) -> some View {
        GroupBox {
            VStack(alignment: .leading) {
                Text(overview)
                    .font(.callout)
                    .padding([.top], 2)
                    .lineLimit(showFullText ? nil : 4)
                    .multilineTextAlignment(.leading)
#if os(iOS)
                if overview.count > 180 {
                    Text(showFullText ? "Collapse" : "Show More")
                        .fontDesign(.rounded)
                        .textCase(.uppercase)
                        .font(.caption)
                        .foregroundStyle(settings.appTheme.color)
                        .padding(.top, 4)
                }
#endif
            }
        } label: {
            Text(type == .person ? "Biography" : "About")
                .unredacted()
        }
        .onTapGesture {
#if os(iOS)
            if UIDevice.isIPad {
                if showAsPopover {
                    showSheet.toggle()
                } else {
                    withAnimation { showFullText.toggle() }
                }
            } else {
                withAnimation { showFullText.toggle() }
            }
#elseif os(macOS)
            showSheet.toggle()
#endif
        }
        .accessibilityElement(children: .combine)
        .contextMenu { ShareLink(item: overview) }
        .popover(isPresented: $showSheet) {
            ScrollView {
                Text(overview)
                    .unredacted()
                    .padding()
            }
            .frame(width: 400, height: 200, alignment: .center)
        }
#if os(iOS)
        .groupBoxStyle(TransparentGroupBox())
#endif
    }
}

#Preview {
    OverviewBoxView(overview: ItemContent.example.overview,
                    title: ItemContent.example.itemTitle,
                    type: .movie)
}
#endif
