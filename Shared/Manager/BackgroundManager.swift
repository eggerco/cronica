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
	
	func handleWatchingContentRefresh() async {
		let items = self.fetchWatchingItems()
		await self.fetchUpdates(items: items)
	}
	
	func handleUpcomingContentRefresh() async {
		var items = [WatchlistItem]()
		let upcomingItems = self.fetchUpcomingItems()
		items.append(contentsOf: upcomingItems)
		if items.isEmpty { return }
		await self.fetchUpdates(items: items)
	}
	
	func handleAppRefreshMaintenance() async {
		var items = [WatchlistItem]()
		let releasedAndEndedItems = self.fetchReleasedItems()
		items.append(contentsOf: releasedAndEndedItems)
		if items.isEmpty { return }
		await self.fetchUpdates(items: items)
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
		guard let list = try? context.fetch(request) else { return [] }
		return list
	}
	
	private func fetchReleasedItems() -> [WatchlistItem] {
		let request: NSFetchRequest<WatchlistItem> = WatchlistItem.fetchRequest()
		let endedPredicate = NSPredicate(format: "schedule == %d", ItemSchedule.ended.toInt)
		let archivePredicate = NSPredicate(format: "isArchive == %d", true)
		request.predicate = NSCompoundPredicate(
			type: .or,
			subpredicates: [endedPredicate, archivePredicate]
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
				if item.isMovie {
					await update(item)
				} else {
					if item.isArchive || item.itemSchedule == .ended || item.isWatched {
						if item.itemLastUpdateDate.hasPassedTwoWeek() {
							await update(item)
						}
					} else {
						await update(item)
					}
				}
			}
		}
	}
	
	private func update(_ item: WatchlistItem) async {
		if item.id == 0 { return }
		do {
			let content = try await self.network.fetchItem(id: item.itemId, type: item.itemMedia)
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
            if content.itemFallbackDate >= Calendar.current.startOfDay(for: Date()),
               content.itemStatus != .cancelled {
                CalendarManager.shared.schedule(content)
            }
			PersistenceController.shared.update(item: content)
		} catch {
			AppLogger.background.error("Failed to refresh item \(item.itemContentID): \(error.localizedDescription)")
		}
	}
}
