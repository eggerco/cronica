//
//  QuickActionRefreshBridge.swift
//  Cronica
//

#if os(iOS) && !CRONICA_SHARE_EXTENSION
enum QuickActionRefreshBridge {
    static func refreshIfAvailable() {
        Task { @MainActor in
            QuickActionManager.refreshShortcuts()
        }
    }
}
#endif
