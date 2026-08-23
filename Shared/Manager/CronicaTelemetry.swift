//
//  CronicaTelemetry.swift
//  Cronica
//
//  Created by Alexandre Madeira on 03/10/22.
//

import Foundation
import Aptabase

struct CronicaTelemetry {
    static let shared = CronicaTelemetry()
    
    private init() { }
    
    func setup() {
#if !targetEnvironment(simulator) && !DEBUG
        guard let aptabaseKey = Key.aptabaseClientKey, !aptabaseKey.isEmpty else { return }
        Aptabase.shared.initialize(appKey: aptabaseKey)
        Aptabase.shared.trackEvent("app_started")
#endif
    }
    
    /// Send a signal using Aptabase service (on iOS/iPadOS) or in Aptabase (macOS, watchOS, tvOS).
    ///
    /// If it is running in Simulator or Debug, it will send a warning on logger.
    func handleMessage(_ message: String, for id: String) {
#if targetEnvironment(simulator) || DEBUG
        AppLogger.lifecycle.warning("\(message), for: \(id)")
#else
        Aptabase.shared.trackEvent(id, with: ["Message": message])
#endif
    }
}
