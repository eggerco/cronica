//
//  SiriShortcutRefreshBridge.swift
//  Cronica
//

#if canImport(AppIntents) && !os(watchOS) && !os(tvOS)
import AppIntents

enum SiriShortcutRefreshBridge {
    static func refreshIfAvailable() {
#if !targetEnvironment(simulator)
        CronicaAppShortcuts.updateAppShortcutParameters()
#endif
    }
}
#endif
