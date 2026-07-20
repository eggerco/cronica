//
//  ListFilterView.swift
//  Cronica
//
//  Created by Alexandre Madeira on 05/02/24.
//

import SwiftUI

struct ListFilterView: View {
    @Binding var showView: Bool
    @Binding var sortOrder: WatchlistSortOrder
    @Binding var filter: SmartFiltersTypes
    @Binding var mediaFilter: MediaTypeFilters
    @Binding var showAllItems: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: CronicaDesign.Spacing.lg) {
                    VStack(alignment: .leading, spacing: CronicaDesign.Spacing.sm) {
                        CronicaFilterSectionTitle(title: String(localized: "Library"))
                        CronicaFilterToggleRow(title: String(localized: "Show All"), isOn: $showAllItems)

                        CronicaFilterSectionTitle(title: String(localized: "Media Type"))
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: CronicaDesign.Spacing.xs) {
                                ForEach(MediaTypeFilters.allCases) { type in
                                    CronicaFilterChip(
                                        title: type.localizableTitle,
                                        isSelected: mediaFilter == type
                                    ) {
                                        withAnimation(CronicaDesign.Motion.standard) {
                                            mediaFilter = type
                                        }
                                    }
                                    .disabled(!showAllItems && type != .showAll)
                                    .opacity((!showAllItems && type != .showAll) ? 0.45 : 1)
                                }
                            }
                            .padding(.horizontal, CronicaDesign.Spacing.md)
                        }
                    }

                    VStack(alignment: .leading, spacing: CronicaDesign.Spacing.sm) {
                        CronicaFilterSectionTitle(title: String(localized: "Sort Order"))
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: CronicaDesign.Spacing.xs) {
                                ForEach(WatchlistSortOrder.allCases) { item in
                                    CronicaFilterChip(
                                        title: item.localizableName,
                                        isSelected: sortOrder == item
                                    ) {
                                        withAnimation(CronicaDesign.Motion.standard) {
                                            sortOrder = item
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, CronicaDesign.Spacing.md)
                        }
                    }

                    VStack(alignment: .leading, spacing: CronicaDesign.Spacing.sm) {
                        CronicaFilterSectionTitle(title: String(localized: "Smart Filters"))
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 140), spacing: CronicaDesign.Spacing.xs)],
                            spacing: CronicaDesign.Spacing.xs
                        ) {
                            ForEach(SmartFiltersTypes.allCases) { item in
                                CronicaFilterChip(
                                    title: item.title,
                                    isSelected: filter == item
                                ) {
                                    withAnimation(CronicaDesign.Motion.standard) {
                                        filter = item
                                    }
                                }
                                .disabled(showAllItems)
                                .opacity(showAllItems ? 0.45 : 1)
                            }
                        }
                        .padding(.horizontal, CronicaDesign.Spacing.md)

                        if showAllItems {
                            Text("Smart Filters only works when 'Show All Items' is disabled.")
                                .font(CronicaDesign.Typography.caption())
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, CronicaDesign.Spacing.md)
                        }
                    }
                }
                .padding(.bottom, CronicaDesign.Spacing.xl)
            }
            .navigationTitle("Filters")
#if !os(tvOS) && !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
#if !os(macOS)
                ToolbarItem(placement: .topBarLeading) {
                    RoundedCloseButton { showView = false }
                }
#else
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showView = false }
                }
#endif
            }
            .scrollBounceBehavior(.basedOnSize)
            .onChange(of: filter) { _, _ in showView = false }
            .onChange(of: sortOrder) { _, _ in showView = false }
            .onChange(of: showAllItems) { _, _ in showView = false }
            .onChange(of: mediaFilter) { _, _ in
                if showAllItems { showView = false }
            }
        }
#if !os(tvOS)
        .cronicaFilterSheet()
        .presentationDetents([.medium, .large])
        .appTint()
        .appTheme()
#endif
    }
}
