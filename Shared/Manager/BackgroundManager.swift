//
//  BackgroundManager.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 12/04/22.
//

import Foundation
import CoreData
import CronicaCore

final class BackgroundManager {
	private let context = PersistenceController.shared.container.newBackgroundContext()
	private let network = NetworkService.shared
	private let notifications = NotificationManager.shared
	private static let lastMaintenanceKey = "lastMaintenance"
	private static let lastWatchingRefreshKey = "lastWatchingRefreshKey"
	private static let lastUpcomingRefreshKey = "lastUpcomingRefreshKey"
	static let shared = BackgroundManager()

	private struct RefreshTarget: Sendable {
		let contentID: String
		let itemId: Int
		let media: MediaType
		let shouldNotify: Bool
		let isArchive: Bool
		let isWatched: Bool
		let isMovie: Bool
		let schedule: ItemSchedule
		let itemDate: Date?
		let lastUpdate: Date
	}
	
	private init() {
		context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		context.automaticallyMergesChangesFromParent = true
	}
	
	var lastMaintenance: Date? {
		get {
			return UserDefaults.standard.object(forKey: BackgroundManager.lastMaintenanceKey) as? Date
		}
		set {
			UserDefaults.standard.set(newValue, forKey: BackgroundManager.lastMaintenanceKey)
		}
	}
	var lastWatchingRefresh: Date? {
		get {
			return UserDefaults.standard.object(forKey: BackgroundManager.lastWatchingRefreshKey) as? Date
		}
		set {
			UserDefaults.standard.set(newValue, forKey: BackgroundManager.lastWatchingRefreshKey)
		}
	}
	var lastUpcomingRefresh: Date? {
		get {
			return UserDefaults.standard.object(forKey: BackgroundManager.lastUpcomingRefreshKey) as? Date
		}
		set {
			UserDefaults.standard.set(newValue, forKey: BackgroundManager.lastUpcomingRefreshKey)
		}
	}
	
	func handleWatchingContentRefresh() async {
		let items = self.fetchWatchingItems()
		await self.fetchUpdates(items: items)
		WidgetSnapshotPublisherBridge.scheduleRefreshIfAvailable()
	}
	
	func handleUpcomingContentRefresh() async {
		let items = self.fetchUpcomingItems()
		if items.isEmpty { return }
		await self.fetchUpdates(items: items)
		WidgetSnapshotPublisherBridge.scheduleRefreshIfAvailable()
	}
	
	func handleAppRefreshMaintenance() async {
		let items = self.fetchReleasedItems()
		if items.isEmpty { return }
		await self.fetchUpdates(items: items)
	}
	
	private func fetchWatchingItems() -> [RefreshTarget] {
		let request: NSFetchRequest<WatchlistItem> = WatchlistItem.fetchRequest()
		let watchingPredicate = NSPredicate(format: "isWatching == %d", true)
		let archivePredicate = NSPredicate(format: "isArchive == %d", false)
		let watchedPredicate = NSPredicate(format: "watched == %d", false)
		let archiveAndWatchedPredicate = NSCompoundPredicate(
			type: .and,
			subpredicates: [archivePredicate,
							watchedPredicate]
		)
		let orPredicate = NSCompoundPredicate(
			type: .and,
			subpredicates: [archiveAndWatchedPredicate,
							watchingPredicate]
		)
		request.predicate = orPredicate
		return mapTargets(fetching: request)
	}
	
	private func fetchUpcomingItems() -> [RefreshTarget] {
		let request: NSFetchRequest<WatchlistItem> = WatchlistItem.fetchRequest()
		let soonPredicate = NSPredicate(format: "schedule == %d", ItemSchedule.soon.toInt)
		let renewedPredicate = NSPredicate(format: "schedule == %d", ItemSchedule.renewed.toInt)
		let productionPredicate = NSPredicate(format: "schedule == %d", ItemSchedule.production.toInt)
		let archivePredicate = NSPredicate(format: "isArchive == %d", false)
		let watchedPredicate = NSPredicate(format: "watched == %d", false)
		let schedulePredicate = NSCompoundPredicate(
			type: .or,
			subpredicates: [productionPredicate, soonPredicate, renewedPredicate]
		)
		let filterPredicate = NSCompoundPredicate(
			type: .and,
			subpredicates: [schedulePredicate, archivePredicate, watchedPredicate]
		)
		request.predicate = filterPredicate
		return mapTargets(fetching: request)
	}
	
	private func fetchReleasedItems() -> [RefreshTarget] {
		let request: NSFetchRequest<WatchlistItem> = WatchlistItem.fetchRequest()
		let endedPredicate = NSPredicate(format: "schedule == %d", ItemSchedule.ended.toInt)
		let archivePredicate = NSPredicate(format: "isArchive == %d", true)
		request.predicate = NSCompoundPredicate(
			type: .or,
			subpredicates: [endedPredicate, archivePredicate]
		)
		return mapTargets(fetching: request)
	}

	private func mapTargets(fetching request: NSFetchRequest<WatchlistItem>) -> [RefreshTarget] {
		var targets: [RefreshTarget] = []
		context.performAndWait {
			guard let list = try? context.fetch(request) else { return }
			targets = list.compactMap { item in
				guard item.itemId != 0 else { return nil }
				return RefreshTarget(
					contentID: item.itemContentID,
					itemId: item.itemId,
					media: item.itemMedia,
					shouldNotify: item.shouldNotify,
					isArchive: item.isArchive,
					isWatched: item.isWatched,
					isMovie: item.isMovie,
					schedule: item.itemSchedule,
					itemDate: item.itemDate,
					lastUpdate: item.itemLastUpdateDate
				)
			}
		}
		return targets
	}
	
	/// Updates every item in the items array, update it in CoreData if needed, and update notification schedule.
	private func fetchUpdates(items: [RefreshTarget]) async {
		for item in items {
			if item.isMovie {
				await update(item)
			} else if item.isArchive || item.schedule == .ended || item.isWatched {
				if item.lastUpdate.hasPassedTwoWeek() {
					await update(item)
				}
			} else {
				await update(item)
			}
		}
	}
	
	private func update(_ item: RefreshTarget) async {
		do {
			let content = try await self.network.fetchItem(id: item.itemId, type: item.media)
			if content.itemCanNotify && item.shouldNotify {
                if item.itemDate.areDifferentDates(with: content.itemFallbackDate) {
                    notifications.removeNotification(identifier: content.itemContentID)
                }
                if content.itemStatus == .cancelled {
                    notifications.removeNotification(identifier: content.itemContentID)
                }
                if content.itemFallbackDate.isLessThanTwoWeeksAway() {
                    notifications.schedule(content)
                }
			}
            if item.itemDate.areDifferentDates(with: content.itemFallbackDate) || content.itemStatus == .cancelled {
                CalendarManager.shared.removeEvent(identifier: content.itemContentID)
            }
            if !item.isArchive, content.itemStatus != .cancelled {
                CalendarManager.shared.schedule(content)
            }
			PersistenceController.shared.update(item: content)
		} catch {
			AppLogger.background.error("Failed to refresh item \(item.contentID): \(error.localizedDescription)")
#if !os(watchOS)
			SentryManager.capture(error, context: ["source": "BackgroundManager.update", "contentID": item.contentID])
#endif
		}
	}
}
