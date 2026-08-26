//
//  WatchingSessionManager.swift
//  Cronica
//

import CronicaCore
import Foundation
#if os(iOS)
import ActivityKit
import UIKit
#endif

#if os(iOS)
enum WatchingSessionResult: Equatable {
    case started
    case stopped
    case disabled
    case unavailable
    case failed
}

@MainActor
final class WatchingSessionManager: ObservableObject {
    static let shared = WatchingSessionManager()

    @Published private(set) var activeContentID: String?
    @Published private(set) var lastErrorMessage: String?

    private static let posterMaxDimension: CGFloat = 240

    private var completionTask: Task<Void, Never>?
    private var startedAt: Date?
    private var runtimeMinutes: Int = 0

    private init() {}

    var isTrackingActive: Bool {
        activeContentID != nil
    }

    var areLiveActivitiesAvailable: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    func isTracking(contentID: String) -> Bool {
        activeContentID == contentID
    }

    func restoreExistingActivitiesIfNeeded() {
        let activities = Activity<WatchingActivityAttributes>.activities
        guard let activity = activities.first else {
            activeContentID = nil
            return
        }

        activeContentID = activity.attributes.contentID
        startedAt = activity.attributes.startedAt
        runtimeMinutes = activity.attributes.totalMinutes

        if isPastCompletion(startedAt: activity.attributes.startedAt, totalMinutes: activity.attributes.totalMinutes) {
            Task { await endSession(reloadWidgets: true) }
            return
        }

        scheduleAutoEndIfNeeded()
    }

    /// Ends any Live Activity whose estimated runtime has elapsed (e.g. after returning to foreground).
    func endCompletedSessionsIfNeeded() {
        guard let startedAt, runtimeMinutes > 0 else { return }
        if isPastCompletion(startedAt: startedAt, totalMinutes: runtimeMinutes) {
            Task { await endSession(reloadWidgets: true) }
        }
    }

    @discardableResult
    func start(for item: WatchlistItem, subtitle: String? = nil) async -> WatchingSessionResult {
        lastErrorMessage = nil

        if !areLiveActivitiesAvailable {
#if !targetEnvironment(simulator)
            lastErrorMessage = String(localized: "Turn on Live Activities for Cronica in Settings to track on the Lock Screen.")
            return .disabled
#endif
        }

        await endSession(reloadWidgets: false)

        // Poster is stored in the App Group — not in Activity attributes (4KB limit).
        await cachePoster(for: item)

        let title = item.itemTitle
        let detail = subtitle ?? defaultSubtitle(for: item)
        let totalMinutes = estimatedRuntimeMinutes(for: item)
        let sessionStart = Date()
        runtimeMinutes = totalMinutes

        return await requestActivity(
            contentID: item.itemContentID,
            title: title,
            subtitle: detail,
            totalMinutes: totalMinutes,
            startedAt: sessionStart
        )
    }

    @discardableResult
    func endSession(reloadWidgets: Bool = true) async -> WatchingSessionResult {
        completionTask?.cancel()
        completionTask = nil
        startedAt = nil
        runtimeMinutes = 0

        if let contentID = activeContentID {
            LiveActivityPosterStore.remove(contentID: contentID)
        }

        for activity in Activity<WatchingActivityAttributes>.activities {
            let finalState = activity.content.state
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )
        }

        let wasActive = activeContentID != nil
        activeContentID = nil

        if reloadWidgets {
            WidgetSnapshotPublisher.shared.scheduleRefresh()
        }
        return wasActive ? .stopped : .unavailable
    }

    @discardableResult
    func toggle(for item: WatchlistItem, subtitle: String? = nil) async -> WatchingSessionResult {
        if isTracking(contentID: item.itemContentID) {
            return await endSession()
        }
        return await start(for: item, subtitle: subtitle)
    }

    // MARK: - Private

    private func requestActivity(
        contentID: String,
        title: String,
        subtitle: String,
        totalMinutes: Int,
        startedAt: Date
    ) async -> WatchingSessionResult {
        let attributes = WatchingActivityAttributes(
            contentID: contentID,
            totalMinutes: totalMinutes,
            startedAt: startedAt
        )
        // Progress is computed in the Live Activity UI from startedAt — these values are seed only.
        let state = WatchingActivityAttributes.ContentState(
            title: title,
            subtitle: subtitle,
            elapsedMinutes: 0,
            remainingMinutes: totalMinutes,
            progress: 0
        )
        let endDate = startedAt.addingTimeInterval(TimeInterval(max(totalMinutes, 1) * 60))

        do {
            _ = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: endDate),
                pushType: nil
            )
            activeContentID = contentID
            self.startedAt = startedAt
            scheduleAutoEndIfNeeded()
            lastErrorMessage = nil
            return .started
        } catch {
            AppLogger.persistence.error("Failed to start Live Activity: \(error.localizedDescription)")
            SentryManager.capture(error, context: ["source": "WatchingSessionManager.start"])
            lastErrorMessage = error.localizedDescription
            LiveActivityPosterStore.remove(contentID: contentID)
            if !areLiveActivitiesAvailable {
                return .disabled
            }
            return .failed
        }
    }

    private func scheduleAutoEndIfNeeded() {
        completionTask?.cancel()
        guard let startedAt, runtimeMinutes > 0 else { return }

        let endDate = startedAt.addingTimeInterval(TimeInterval(runtimeMinutes * 60))
        let delay = endDate.timeIntervalSinceNow
        guard delay > 0 else {
            Task { await endSession(reloadWidgets: true) }
            return
        }

        completionTask = Task { [weak self] in
            let nanoseconds = UInt64(delay * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
            guard !Task.isCancelled else { return }
            await self?.endSession(reloadWidgets: true)
        }
    }

    private func isPastCompletion(startedAt: Date, totalMinutes: Int) -> Bool {
        guard totalMinutes > 0 else { return false }
        let end = startedAt.addingTimeInterval(TimeInterval(totalMinutes * 60))
        return Date() >= end
    }

    private func defaultSubtitle(for item: WatchlistItem) -> String {
        if item.isTvShow {
            let season = Int(item.itemNextUpNextSeason)
            let episode = Int(item.itemNextUpNextEpisode)
            return String(format: String(localized: "S%d · E%d"), season, episode)
        }
        let minutes = Int(item.runtimeMinutes)
        if minutes > 0 {
            return minutes.convertToLongRuntime()
        }
        return String(localized: "Watching now")
    }

    private func estimatedRuntimeMinutes(for item: WatchlistItem) -> Int {
        let minutes = Int(item.runtimeMinutes)
        if minutes > 0 { return minutes }
        return item.isMovie ? 120 : 45
    }

    private func cachePoster(for item: WatchlistItem) async {
        guard let imageURL = posterURL(for: item) else {
            AppLogger.persistence.warning("No TMDb poster URL for Live Activity \(item.itemContentID)")
            return
        }

        do {
            let data = try await NetworkService.shared.downloadData(from: imageURL)
            guard let jpeg = makeThumbnail(from: data) else {
                AppLogger.persistence.warning("Poster thumbnail encode failed for \(item.itemContentID)")
                return
            }
            LiveActivityPosterStore.save(jpeg, contentID: item.itemContentID)
            let fileName = WidgetSnapshotStore.posterFileName(for: item.itemContentID)
            try? WidgetSnapshotStore.writePoster(jpeg, fileName: fileName)
        } catch {
            AppLogger.persistence.error(
                "Live Activity TMDb poster download failed for \(item.itemContentID): \(error.localizedDescription)"
            )
        }
    }

    private func posterURL(for item: WatchlistItem) -> URL? {
        if let path = item.posterPath, !path.isEmpty {
            return NetworkService.urlBuilder(size: .medium, path: path)
                ?? NetworkService.urlBuilder(size: .small, path: path)
        }
        return item.backCompatiblePosterImage
            ?? item.itemPosterImageMedium
            ?? item.mediumPosterImage
            ?? item.itemImage
            ?? item.image
    }

    private func makeThumbnail(from data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }

        let maxDimension = Self.posterMaxDimension
        let longest = max(image.size.width, image.size.height)
        let scale = min(1, maxDimension / max(longest, 1))
        let target = CGSize(
            width: max(1, (image.size.width * scale).rounded()),
            height: max(1, (image.size.height * scale).rounded())
        )

        let renderer = UIGraphicsImageRenderer(size: target)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return resized.jpegData(compressionQuality: 0.72)
    }
}
#endif

enum WatchingSessionManagerBridge {
    static func restoreIfAvailable() {
#if os(iOS)
        if #available(iOS 16.2, *) {
            Task { @MainActor in
                WatchingSessionManager.shared.restoreExistingActivitiesIfNeeded()
            }
        }
#endif
    }

    static func endCompletedIfAvailable() {
#if os(iOS)
        if #available(iOS 16.2, *) {
            Task { @MainActor in
                WatchingSessionManager.shared.endCompletedSessionsIfNeeded()
            }
        }
#endif
    }
}
