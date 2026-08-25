//
//  UpNextEpisode.swift
//  Cronica
//
//  Created by Alexandre Madeira on 07/05/23.
//

import Foundation

struct UpNextEpisode: Identifiable, Hashable {
    let id: Int
    let showTitle: String
    let showID: Int
    let backupImage: URL?
    let episode: Episode
    let sortedDate: Date
    let watchProgress: Double

    var watchProgressLabel: String? {
        guard watchProgress > 0 else { return nil }
        let percent = Int((watchProgress * 100).rounded())
        return String(format: String(localized: "%d%% watched"), percent)
    }
}
