//
//  QuickActionAppDelegate.swift
//  Cronica
//

#if os(iOS)
import UIKit

/// Handles Home Screen quick actions for SwiftUI scene-based lifecycle.
/// Implements both app- and scene-delegate entry points so cold and warm launches are covered.
final class QuickActionAppDelegate: NSObject, UIApplicationDelegate, UIWindowSceneDelegate {
    static let sceneConfigurationName = "Default Configuration"

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        if let shortcut = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem {
            Self.handle(shortcut, source: "didFinishLaunching")
        }

        // Apply UI-test navigation synchronously so TabBarView bootstrap can consume it on first pass.
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                QuickActionManager.applyUITestLaunchActionIfNeeded()
            }
        } else {
            DispatchQueue.main.sync {
                QuickActionManager.applyUITestLaunchActionIfNeeded()
            }
        }

        Task { @MainActor in
            QuickActionManager.refreshShortcuts()
        }
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        if let shortcut = options.shortcutItem {
            Self.handle(shortcut, source: "configurationForConnecting")
        }

        let configuration = UISceneConfiguration(
            name: Self.sceneConfigurationName,
            sessionRole: connectingSceneSession.role
        )
        configuration.delegateClass = QuickActionAppDelegate.self
        return configuration
    }

    func application(
        _ application: UIApplication,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        completionHandler(Self.handle(shortcutItem, source: "applicationPerformAction"))
    }

    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        completionHandler(Self.handle(shortcutItem, source: "windowScenePerformAction"))
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let shortcut = connectionOptions.shortcutItem {
            Self.handle(shortcut, source: "sceneWillConnect")
        }
    }

    @discardableResult
    private static func handle(_ shortcutItem: UIApplicationShortcutItem, source: String) -> Bool {
        QuickActionDebug.log("handle type=\(shortcutItem.type) source=\(source)")

        if Thread.isMainThread {
            return MainActor.assumeIsolated {
                QuickActionManager.handle(shortcutItem)
            }
        }

        var handled = false
        DispatchQueue.main.sync {
            handled = QuickActionManager.handle(shortcutItem)
        }
        return handled
    }
}
#endif
