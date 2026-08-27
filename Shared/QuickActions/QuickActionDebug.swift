//
//  QuickActionDebug.swift
//  Cronica
//

#if os(iOS) && DEBUG
enum QuickActionDebug {
    static func log(_ message: String) {
        print("[Cronica QuickAction] \(message)")
    }
}
#elseif os(iOS)
enum QuickActionDebug {
    static func log(_ message: String) {}
}
#endif
