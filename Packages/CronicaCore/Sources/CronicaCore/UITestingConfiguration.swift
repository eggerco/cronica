//
//  UITestingConfiguration.swift
//  CronicaCore
//

import Foundation

public enum UITestingConfiguration {
    public static let uiTestingArgument = "-ui-testing"
    public static let mockDataArgument = "--mock-data"

    public static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains(uiTestingArgument)
    }

    public static var usesMockData: Bool {
        ProcessInfo.processInfo.arguments.contains(mockDataArgument)
    }

    public static var mockItems: [ItemContent] {
        ItemContent.examples
    }
}
