//
//  SiriShortcutRefreshBridge.swift
//  Cronica
//

#if canImport(AppIntents) && !os(watchOS) && !os(tvOS)
import AppIntents

enum SiriShortcutRefreshBridge {
    static func refreshIfAvailable() {
        CronicaAppShortcuts.updateAppShortcutParameters()
    }
}
#endif
