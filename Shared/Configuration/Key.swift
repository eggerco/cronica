//
//  Key.swift
//  Cronica
//
//  Created by Alexandre Madeira on 28/01/22.
//  swiftlint:disable line_length

import Foundation

/// API keys for TMDb and Aptabase.
///
/// Leave these empty in the repository. Inject real values via local edits,
/// CI secrets, or an untracked override before shipping.
struct Key {
    static let tmdbApi = ""
    static let aptabaseClientKey: String? = ""

    static var hasTMDbKey: Bool {
        !tmdbApi.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static var aptabaseKeyIfAvailable: String? {
        guard let key = aptabaseClientKey?.trimmingCharacters(in: .whitespacesAndNewlines),
              !key.isEmpty else {
            return nil
        }
        return key
    }
}
