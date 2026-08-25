//
//  TabBarReselectDetector.swift
//  Cronica
//

import SwiftUI

#if canImport(UIKit) && !os(macOS) && !os(tvOS)
import UIKit

/// Detects re-taps on the already-selected tab (iOS 18 `Tab` API does not always update selection).
struct TabBarReselectDetector: UIViewControllerRepresentable {
    let tabs: [Screens]
    let onReselect: (Screens) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(tabs: tabs, onReselect: onReselect)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let host = UIViewController()
        host.view.isUserInteractionEnabled = false
        host.view.backgroundColor = .clear
        return host
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        context.coordinator.tabs = tabs
        context.coordinator.onReselect = onReselect
        context.coordinator.attach(from: uiViewController)
    }

    final class Coordinator: NSObject, UITabBarControllerDelegate {
        var tabs: [Screens]
        var onReselect: (Screens) -> Void
        private weak var observedController: UITabBarController?
        private weak var previousDelegate: UITabBarControllerDelegate?

        init(tabs: [Screens], onReselect: @escaping (Screens) -> Void) {
            self.tabs = tabs
            self.onReselect = onReselect
        }

        func attach(from host: UIViewController) {
            guard let found = Self.findTabBarController(from: host),
                  found !== observedController else {
                return
            }

            observedController = found
            previousDelegate = found.delegate
            found.delegate = self
        }

        func tabBarController(
            _ tabBarController: UITabBarController,
            shouldSelect viewController: UIViewController
        ) -> Bool {
            let allowed = previousDelegate?.tabBarController?(tabBarController, shouldSelect: viewController) ?? true

            if tabBarController.selectedViewController === viewController,
               let index = tabBarController.viewControllers?.firstIndex(of: viewController),
               tabs.indices.contains(index) {
                onReselect(tabs[index])
            }

            return allowed
        }

        private static func findTabBarController(from host: UIViewController) -> UITabBarController? {
            var responder: UIResponder? = host
            while let current = responder {
                if let found = current as? UITabBarController {
                    return found
                }
                responder = current.next
            }

            var parent = host.parent
            while let current = parent {
                if let found = current as? UITabBarController {
                    return found
                }
                parent = current.parent
            }

            return nil
        }
    }
}
#endif
