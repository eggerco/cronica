//
//  SimklImportService.swift
//  Cronica
//

import Foundation

/// Compatibility facade — prefer `SimklSyncService` for new call sites.
@MainActor
enum SimklImportService {
    typealias Progress = SimklSyncService.Progress

    static func importLibrary(
        progress: (@MainActor (Progress) -> Void)? = nil
    ) async throws -> SimklImportSummary {
        try await SimklSyncService.fullImport(progress: progress)
    }
}
