//
//  WidgetSnapshotStore.swift
//  CronicaCore
//

import Foundation

public enum WidgetSnapshotStore {
    private static let snapshotsDirectoryName = "snapshots"
    private static let postersDirectoryName = "posters"
    private static let upNextFileName = "up-next.json"
    private static let watchlistFileName = "watchlist.json"

    public static func posterFileName(for contentID: String) -> String {
        contentID
            .replacingOccurrences(of: "@", with: "_")
            .replacingOccurrences(of: "/", with: "_")
            + ".jpg"
    }

    public static func readUpNext() -> WidgetUpNextSnapshot? {
        read(WidgetUpNextSnapshot.self, fileName: upNextFileName)
    }

    public static func readWatchlist() -> WidgetWatchlistSnapshot? {
        read(WidgetWatchlistSnapshot.self, fileName: watchlistFileName)
    }

    public static func writeUpNext(_ snapshot: WidgetUpNextSnapshot) throws {
        try write(snapshot, fileName: upNextFileName)
    }

    public static func writeWatchlist(_ snapshot: WidgetWatchlistSnapshot) throws {
        try write(snapshot, fileName: watchlistFileName)
    }

    public static func writePoster(_ data: Data, fileName: String) throws {
        let url = try posterURL(for: fileName)
        try data.write(to: url, options: [.atomic])
    }

    public static func readPoster(named fileName: String) -> Data? {
        guard let url = try? posterURL(for: fileName) else { return nil }
        return try? Data(contentsOf: url)
    }

    public static func removeAllSnapshots() {
        guard let root = WidgetAppGroup.containerURL else { return }
        let snapshots = root.appendingPathComponent(snapshotsDirectoryName, isDirectory: true)
        let posters = root.appendingPathComponent(postersDirectoryName, isDirectory: true)
        try? FileManager.default.removeItem(at: snapshots)
        try? FileManager.default.removeItem(at: posters)
    }

    /// Deletes poster files that are no longer referenced by current snapshots.
    public static func pruneUnusedPosters(keeping fileNames: Set<String>) {
        guard let root = WidgetAppGroup.containerURL else { return }
        let directory = root.appendingPathComponent(postersDirectoryName, isDirectory: true)
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ) else { return }

        for url in contents {
            let name = url.lastPathComponent
            guard name.hasSuffix(".jpg") || name.hasSuffix(".jpeg") else { continue }
            if !fileNames.contains(name) {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    // MARK: - Private

    private static func read<T: Decodable>(_ type: T.Type, fileName: String) -> T? {
        guard let url = try? snapshotURL(for: fileName),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? JSONDecoder().decode(type, from: data)
    }

    private static func write<T: Encodable>(_ value: T, fileName: String) throws {
        let url = try snapshotURL(for: fileName)
        let data = try JSONEncoder().encode(value)
        try data.write(to: url, options: [.atomic])
    }

    private static func snapshotURL(for fileName: String) throws -> URL {
        let root = try requireContainerURL()
        let directory = root.appendingPathComponent(snapshotsDirectoryName, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent(fileName)
    }

    private static func posterURL(for fileName: String) throws -> URL {
        let root = try requireContainerURL()
        let directory = root.appendingPathComponent(postersDirectoryName, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent(fileName)
    }

    private static func requireContainerURL() throws -> URL {
        guard let url = WidgetAppGroup.containerURL else {
            throw WidgetSnapshotStoreError.missingAppGroupContainer
        }
        return url
    }
}

public enum WidgetSnapshotStoreError: Error {
    case missingAppGroupContainer
}
