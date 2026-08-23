//
//  AppLogger.swift
//  Cronica
//

import Foundation
import os

public enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "dev.alexandremadeira.Story"

    public static let network = Logger(subsystem: subsystem, category: "Network")
    public static let persistence = Logger(subsystem: subsystem, category: "Persistence")
    public static let background = Logger(subsystem: subsystem, category: "Background")
    public static let notifications = Logger(subsystem: subsystem, category: "Notifications")
    public static let lifecycle = Logger(subsystem: subsystem, category: "Lifecycle")
}
