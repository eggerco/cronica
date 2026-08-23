//
//  Int-Extensions.swift
//  Cronica
//
//  Created by Alexandre Madeira on 03/02/23.
//

import Foundation

public extension Int {
    func convertToShortRuntime() -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute]
        let value = formatter.string(from: TimeInterval(self) * 60)
        guard let value else { return String() }
        return value
    }
    
    func convertToLongRuntime() -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.hour, .minute]
        let value = formatter.string(from: TimeInterval(self) * 60)
        guard let value else { return String() }
        return value
    }
}
