//
//  Bundle-Decodable.swift
//  Cronica
//
//  Created by Alexandre Madeira on 17/01/22.
//

import Foundation

public extension Bundle {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "y,MM,dd"
        return formatter
    }()
    
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        return decoder
    }()
    
    func decode<T: Decodable>(from file: String) throws -> T? {
        guard let url = self.url(forResource: file, withExtension: "json") else {
            fatalError("Failed to locate \(file) from bundle.")
        }
        let data = try Data(contentsOf: url)
        let result = try Bundle.decoder.decode(T.self, from: data)
        return result
    }
    
    static func isTestFlight() -> Bool {
#if DEBUG || targetEnvironment(simulator)
        return true
#else
        return Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
#endif
    }
}
