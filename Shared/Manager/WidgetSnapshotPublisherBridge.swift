//
//  WidgetSnapshotPublisherBridge.swift
//  Cronica
//

import Foundation

enum WidgetSnapshotPublisherBridge {
    static func scheduleRefreshIfAvailable() {
#if os(iOS) || os(macOS)
        Task { @MainActor in
            WidgetSnapshotPublisher.shared.scheduleRefresh()
        }
#endif
    }
}
