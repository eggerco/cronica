//
//  CustomList+CoreDataProperties.swift
//  Cronica
//
//  Created by Alexandre Madeira on 11/03/23.
//
//

import Foundation
import CoreData


extension CustomList {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CustomList> {
        return NSFetchRequest<CustomList>(entityName: "CustomList")
    }

    @NSManaged public var creationDate: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var notes: String?
    @NSManaged public var title: String?
    @NSManaged public var updatedDate: Date?
    @NSManaged public var items: NSSet?
    @NSManaged public var isSyncEnabledTMDB: Bool
    @NSManaged public var idOnTMDb: Int64
    @NSManaged public var isPin: Bool
    /// Content IDs in the user's manual order, comma separated.
    @NSManaged public var itemOrder: String?

}

// MARK: Generated accessors for items
extension CustomList {

    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: WatchlistItem)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: WatchlistItem)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: NSSet)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: NSSet)

}

extension CustomList : Identifiable {

}
