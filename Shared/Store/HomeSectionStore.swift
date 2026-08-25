//
//  HomeSectionStore.swift
//  Cronica
//

import Foundation
import SwiftUI

@MainActor
final class HomeSectionStore: ObservableObject {
    static let shared = HomeSectionStore()

    private let orderKey = "homeSectionOrder"
    private let hiddenKey = "homeSectionHidden"

    @Published private(set) var order: [HomeSectionKind]
    @Published private(set) var hidden: Set<HomeSectionKind>

    private init() {
        order = Self.loadOrder()
        hidden = Self.loadHidden()
    }

    var visibleOrderedSections: [HomeSectionKind] {
        order.filter { !hidden.contains($0) }
    }

    func isVisible(_ kind: HomeSectionKind) -> Bool {
        !hidden.contains(kind)
    }

    func setVisible(_ kind: HomeSectionKind, visible: Bool) {
        var next = hidden
        if visible {
            next.remove(kind)
        } else {
            next.insert(kind)
        }
        hidden = next
        persistHidden()
    }

    func move(from offsets: IndexSet, to destination: Int) {
        var next = order
        next.move(fromOffsets: offsets, toOffset: destination)
        order = next
        persistOrder()
    }

    func resetToDefaults() {
        order = HomeSectionKind.defaultOrder
        hidden = Set(HomeSectionKind.allCases.filter { !HomeSectionKind.defaultVisible.contains($0) })
        persistOrder()
        persistHidden()
    }

    private func persistOrder() {
        UserDefaults.standard.set(order.map(\.rawValue), forKey: orderKey)
    }

    private func persistHidden() {
        UserDefaults.standard.set(hidden.map(\.rawValue), forKey: hiddenKey)
    }

    private static func loadOrder() -> [HomeSectionKind] {
        guard let raw = UserDefaults.standard.array(forKey: "homeSectionOrder") as? [String] else {
            return HomeSectionKind.defaultOrder
        }
        var parsed = raw.compactMap(HomeSectionKind.fromPersistedRawValue)
        // Append any newly introduced sections the user hasn't seen yet.
        for kind in HomeSectionKind.defaultOrder where !parsed.contains(kind) {
            parsed.append(kind)
        }
        return parsed.isEmpty ? HomeSectionKind.defaultOrder : parsed
    }

    private static func loadHidden() -> Set<HomeSectionKind> {
        guard let raw = UserDefaults.standard.array(forKey: "homeSectionHidden") as? [String] else {
            return Set(HomeSectionKind.allCases.filter { !HomeSectionKind.defaultVisible.contains($0) })
        }
        return Set(raw.compactMap(HomeSectionKind.fromPersistedRawValue))
    }
}
