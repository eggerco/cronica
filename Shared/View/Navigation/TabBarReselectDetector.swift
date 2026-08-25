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

    func makeUIViewController(context: Context) -> Controller {
        let controller = Controller(tabs: tabs, onReselect: onReselect)
        return controller
    }

    func updateUIViewController(_ uiViewController: Controller, context: Context) {
        uiViewController.tabs = tabs
        uiViewController.onReselect = onReselect
        uiViewController.attachIfNeeded()
    }

    final class Controller: UIViewController, UITabBarControllerDelegate {
        var tabs: [Screens]
        var onReselect: (Screens) -> Void
        private weak var attachedTabBarController: UITabBarController?
        private weak var originalDelegate: UITabBarControllerDelegate?

        init(tabs: [Screens], onReselect: @escaping (Screens) -> Void) {
            self.tabs = tabs
            self.onReselect = onReselect
            super.init(nibName: nil, bundle: nil)
            view.isUserInteractionEnabled = false
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            attachIfNeeded()
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            attachIfNeeded()
        }

        func attachIfNeeded() {
            guard let tabBarController = locateTabBarController(),
                  tabBarController !== attachedTabBarController else {
                return
            }

            attachedTabBarController = tabBarController
            originalDelegate = tabBarController.delegate
            tabBarController.delegate = self
        }

        func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
            let defaultShouldSelect = originalDelegate?.tabBarController?(tabBarController, shouldSelect: viewController) ?? true

            if tabBarController.selectedViewController === viewController,
               let index = tabBarController.viewControllers?.firstIndex(of: viewController),
               tabs.indices.contains(index) {
                onReselect(tabs[index])
            }

            return defaultShouldSelect
        }

        private func locateTabBarController() -> UITabBarController? {
            var responder: UIResponder? = view
            while let current = responder {
                if let tabBarController = current as? UITabBarController {
                    return tabBarController
                }
                responder = current.next
            }
            return nil
        }
    }
}
#endif
