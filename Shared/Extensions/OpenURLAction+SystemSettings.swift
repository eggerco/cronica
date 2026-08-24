//
//  OpenURLAction+SystemSettings.swift
//  Cronica
//

import SwiftUI

#if os(iOS)
import UIKit

extension OpenURLAction {
    /// Opens this app's page in the Settings app.
    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        self(url)
    }

    /// Opens this app's notification settings in the Settings app.
    func openNotificationSettings() {
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return }
        self(url)
    }
}
#endif
