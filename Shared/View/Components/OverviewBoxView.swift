//
//  OverviewBoxView.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 25/04/22.
//

import SwiftUI
#if !os(tvOS)
/// Displays the overview of a movie, tv show, or episode.
/// It can also display biography.
struct OverviewBoxView: View {
    let overview: String?
    let title: String
    var type: MediaType = .movie
    var showAsPopover = false
    var plainStyle = false
    @State private var showFullText = false
    @State private var showSheet = false
    @State private var isTruncated = false
    @StateObject private var settings = SettingsStore.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var expandAnimation: Animation? {
        reduceMotion ? nil : .easeInOut(duration: 0.22)
    }

    var body: some View {
        if let overview {
            if !overview.isEmpty {
                if plainStyle {
                    plainOverview(overview)
                } else {
                    groupedOverview(overview)
                }
            }
        }
    }

    @ViewBuilder
    private func plainOverview(_ overview: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(overview)
                .font(.callout)
                .foregroundStyle(.primary)
                .lineLimit(showFullText ? nil : 4)
                .multilineTextAlignment(.leading)
                .animation(expandAnimation, value: showFullText)
                .accessibilityIdentifier("Overview Text")
#if os(iOS)
                .background(truncationMeasurer(for: overview))
                .contentShape(Rectangle())
                .onTapGesture {
                    guard isTruncated else { return }
                    if let expandAnimation {
                        withAnimation(expandAnimation) { showFullText.toggle() }
                    } else {
                        showFullText.toggle()
                    }
                }
#endif
            if isTruncated || showFullText {
                Button {
                    if let expandAnimation {
                        withAnimation(expandAnimation) { showFullText.toggle() }
                    } else {
                        showFullText.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(showFullText ? String(localized: "Show Less") : String(localized: "Show More"))
                        Image(systemName: showFullText ? "chevron.up" : "chevron.down")
                            .font(.caption2.weight(.semibold))
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(settings.appTheme.color)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onChange(of: overview) { _, _ in
            showFullText = false
            isTruncated = false
        }
        .contextMenu { ShareLink(item: overview) }
    }

    @ViewBuilder
    private func groupedOverview(_ overview: String) -> some View {
                GroupBox {
                    VStack(alignment: .leading) {
                        Text(overview)
                            .font(.callout)
                            .padding([.top], 2)
                            .lineLimit(showFullText ? nil : 4)
                            .multilineTextAlignment(.leading)
                            .animation(expandAnimation, value: showFullText)
                            .accessibilityIdentifier("Overview Text")
#if os(iOS)
                            .background(
                                Text(overview)
                                    .lineLimit(4)
                                    .font(.callout)
                                    .padding([.top], 2)
                                    .background(GeometryReader { displayedGeometry in
                                        ZStack {
                                            Text(overview)
                                                .font(.callout)
                                                .padding([.top], 2)
                                                .background(GeometryReader { fullGeometry in
                                                    Color.clear.onAppear {
                                                        self.isTruncated = fullGeometry.size.height > displayedGeometry.size.height
                                                    }
                                                })
                                        }
                                        .frame(height: .greatestFiniteMagnitude)
                                    })
                                    .hidden()
                            )
#endif

#if os(iOS)
                        if isTruncated {
                            Text(showFullText ? "Collapse" : "Show More")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(settings.appTheme.color)
                                .padding(.top, 4)
                                .accessibilityAddTraits(.isButton)
                                .accessibilityHint(showFullText
                                                   ? Text("Hide the full overview")
                                                   : Text("Show the full overview"))
                        }
#endif
                    }
                } label: {
                    Text(type == .person ? "Biography" : "About")
                        .unredacted()
                        .accessibilityIdentifier("About Text")
                }
                .onTapGesture {
#if os(iOS)
                    if horizontalSizeClass == .regular, showAsPopover {
                        showSheet.toggle()
                    } else if let expandAnimation {
                        withAnimation(expandAnimation) { showFullText.toggle() }
                    } else {
                        showFullText.toggle()
                    }
#elseif os(macOS)
                    showSheet.toggle()
#endif
                }
                .accessibilityElement(children: .combine)
                .accessibilityAction {
#if os(iOS)
                    showFullText.toggle()
#endif
                }
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

#if os(iOS)
    private func truncationMeasurer(for overview: String) -> some View {
        Text(overview)
            .lineLimit(4)
            .font(.callout)
            .background(
                GeometryReader { displayedGeometry in
                    Text(overview)
                        .font(.callout)
                        .fixedSize(horizontal: false, vertical: true)
                        .background(
                            GeometryReader { fullGeometry in
                                Color.clear
                                    .onAppear { updateTruncation(displayed: displayedGeometry.size, full: fullGeometry.size) }
                                    .onChange(of: displayedGeometry.size) { _, newSize in
                                        updateTruncation(displayed: newSize, full: fullGeometry.size)
                                    }
                            }
                        )
                }
            )
            .hidden()
    }

    private func updateTruncation(displayed: CGSize, full: CGSize) {
        isTruncated = full.height > displayed.height + 1
    }
#endif
}

#Preview {
    OverviewBoxView(overview: ItemContent.example.overview,
                    title: ItemContent.example.itemTitle,
                    type: .movie)
}
#endif
