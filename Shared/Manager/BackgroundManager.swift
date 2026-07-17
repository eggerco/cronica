//
//  BackgroundManager.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 12/04/22.
//

import Foundation
import CoreData

final class BackgroundManager {
	private let context = PersistenceController.shared.container.newBackgroundContext()
	private let network = NetworkService.shared
	private let notifications = NotificationManager.shared
	private static let lastMaintenanceKey = "lastMaintenance"
	private static let lastWatchingRefreshKey = "lastWatchingRefreshKey"
	private static let lastUpcomingRefreshKey = "lastUpcomingRefreshKey"
	static let shared = BackgroundManager()
	
	private init() { }
	
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
	
	private let minimumRefreshInterval: TimeInterval = 6 * 60 * 60

	func handleWatchingContentRefresh(force: Bool = false) async {
		if !force, let last = lastWatchingRefresh, Date().timeIntervalSince(last) < minimumRefreshInterval {
			return
		}
		let items = self.fetchWatchingItems()
		await self.fetchUpdates(items: items)
		lastWatchingRefresh = Date()
	}
	
	func handleUpcomingContentRefresh(force: Bool = false) async {
		if !force, let last = lastUpcomingRefresh, Date().timeIntervalSince(last) < minimumRefreshInterval {
			return
		}
		var items = [WatchlistItem]()
		let upcomingItems = self.fetchUpcomingItems()
		items.append(contentsOf: upcomingItems)
		if items.isEmpty { return }
		await self.fetchUpdates(items: items)
		lastUpcomingRefresh = Date()
	}
	
	func handleAppRefreshMaintenance(force: Bool = false) async {
		if !force, let last = lastMaintenance, Date().timeIntervalSince(last) < minimumRefreshInterval {
			return
		}
		var items = [WatchlistItem]()
		let releasedAndEndedItems = self.fetchReleasedItems()
		items.append(contentsOf: releasedAndEndedItems)
		if items.isEmpty { return }
		await self.fetchUpdates(items: items)
		lastMaintenance = Date()
	}
	
	private func fetchWatchingItems() -> [WatchlistItem] {
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
		guard let list = try? context.fetch(request) else { return [] }
		return list
	}
	
	private func fetchUpcomingItems() -> [WatchlistItem] {
		let request: NSFetchRequest<WatchlistItem> = WatchlistItem.fetchRequest()
		let soonPredicate = NSPredicate(format: "schedule == %d", ItemSchedule.soon.toInt)
		let renewedPredicate = NSPredicate(format: "schedule == %d", ItemSchedule.renewed.toInt)
		let productionPredicate = NSPredicate(format: "schedule == %d", ItemSchedule.production.toInt)
		let orPredicate = NSCompoundPredicate(
			type: .or,
			subpredicates: [productionPredicate,
							soonPredicate,
							renewedPredicate]
		)
		let andPredicate = NSCompoundPredicate(type: .and, subpredicates: [orPredicate])
		request.predicate = andPredicate
		guard let list = try? context.fetch(request) else { return [] }
		return list
	}
	
	private func fetchReleasedItems() -> [WatchlistItem] {
		let request: NSFetchRequest<WatchlistItem> = WatchlistItem.fetchRequest()
		let endedPredicate = NSPredicate(format: "schedule == %d", ItemSchedule.ended.toInt)
		let archivePredicate = NSPredicate(format: "isArchive == %d", true)
		request.predicate = NSCompoundPredicate(
			type: .or,
			subpredicates: [endedPredicate,
							archivePredicate]
		)
		guard let list = try? self.context.fetch(request) else { return [] }
		return list
	}
	
	/// Updates every item in the items array, update it in CoreData if needed, and update notification schedule.
	private func fetchUpdates(items: [WatchlistItem]) async {
		if !items.isEmpty {
			for item in items {
				// if the item is already released, archive or watched
				// the need for constant updates are not there.
				// So, to save resources, they will update less frequently.
				if item.isArchive || item.isWatched || (!item.isMovie && item.itemSchedule == .ended) {
					if item.itemLastUpdateDate.hasPassedTwoWeek() {
						await update(item)
					}
				} else {
					await update(item)
				}
			}
		}
	}
	
	private func update(_ item: WatchlistItem) async {
		if item.id == 0 { return }
		let content = try? await self.network.fetchItem(id: item.itemId, type: item.itemMedia)
		guard let content else { return }
		if content.itemCanNotify && item.shouldNotify {
			// If fetched item release date is different than the scheduled one,
			// then remove the old date and register the new one.
			if item.itemDate.areDifferentDates(with: content.itemFallbackDate) {
				notifications.removeNotification(identifier: content.itemContentID)
			}
			if content.itemStatus == .cancelled {
				notifications.removeNotification(identifier: content.itemContentID)
			}
			// Stay under local notification limits by only scheduling
			// when release is less than two weeks away.
			if content.itemFallbackDate.isLessThanTwoWeeksAway() {
				notifications.schedule(content)
			}
		}
		PersistenceController.shared.update(item: content)
	}
}
