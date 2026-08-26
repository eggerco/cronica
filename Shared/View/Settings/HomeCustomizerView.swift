//
//  HomeCustomizerView.swift
//  Cronica
//

import SwiftUI

/// Show, hide, and reorder Home rails (issue #34 phase 1–2).
struct HomeCustomizerView: View {
    @ObservedObject private var store = HomeSectionStore.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                ForEach(store.order) { section in
                    Toggle(isOn: Binding(
                        get: { store.isVisible(section) },
                        set: { store.setVisible(section, visible: $0) }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(section.title)
                            Text(section.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onMove(perform: store.move)
            } header: {
                Text("Home Sections")
            } footer: {
                Text("Drag to reorder. Turn off a section to hide it from Home. Catalog lists load from TMDB.")
            }

            Section {
                Button("Reset Home Layout", role: .destructive) {
                    store.resetToDefaults()
                }
            }
        }
#if os(iOS) || os(visionOS)
        .environment(\.editMode, .constant(.active))
#endif
        .navigationTitle("Customize Home")
#if os(iOS) || os(visionOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
}

#Preview {
    NavigationStack {
        HomeCustomizerView()
    }
}
