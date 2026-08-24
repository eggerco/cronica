//
//  CronicaTelemetry.swift
//  Cronica
//
//  Created by Alexandre Madeira on 03/10/22.
//

import Foundation

/// Lightweight diagnostic helper. Crash reporting is handled by Sentry.
struct CronicaTelemetry {
    static let shared = CronicaTelemetry()

    private init() { }

    func setup() { }

    /// Logs diagnostic messages in Debug / Simulator only.
    func handleMessage(_ message: String, for id: String) {
#if targetEnvironment(simulator) || DEBUG
        AppLogger.lifecycle.warning("\(message), for: \(id)")
#endif
    }
}
