//
//  EntityPosterImage.swift
//  Cronica
//

#if canImport(AppIntents) && !os(watchOS) && !os(tvOS)
import AppIntents
import CronicaCore

enum EntityPosterImage {
    static func intentImage(for contentID: String) -> DisplayRepresentation.Image? {
        let fileName = WidgetSnapshotStore.posterFileName(for: contentID)
        guard let data = WidgetSnapshotStore.readPoster(named: fileName),
              let url = writeTemporaryPoster(data: data, name: fileName)
        else { return nil }
        return DisplayRepresentation.Image(url: url)
    }

    private static func writeTemporaryPoster(data: Data, name: String) -> URL? {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("cronica-intent-posters", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appendingPathComponent("\(name).jpg")
        guard (try? data.write(to: fileURL, options: .atomic)) != nil else { return nil }
        return fileURL
    }
}
#endif
