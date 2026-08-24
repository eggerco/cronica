//
//  PersistenceController-CustomList.swift
//  Cronica
//
//  Created by Alexandre Madeira on 14/02/23.
//

import Foundation

extension PersistenceController {
    func createList(title: String, description: String, items: Set<WatchlistItem>, isPin: Bool) -> CustomList? {
        let viewContext = container.viewContext
        let list = CustomList(context: viewContext)
        list.id = UUID()
        list.title = title
        list.creationDate = Date()
        list.updatedDate = Date()
        list.notes = description
        list.items = items as NSSet
        list.isPin = isPin
        save()
        return list
    }
    
    func delete(_ list: CustomList) {
        let viewContext = container.viewContext
        let item = try? viewContext.existingObject(with: list.objectID)
        guard let item else { return }
        viewContext.delete(item)
        save()
    }

    func deleteList(_ list: CustomList, includingWatchlistItems: Bool) {
        if includingWatchlistItems {
            let itemsToDelete = list.itemsArray
            delete(list)
            for item in itemsToDelete {
                delete(item)
            }
        } else {
            delete(list)
        }
    }
    
    func isItemOnList(id: String, list: CustomList) -> Bool {
        return list.itemsSet.contains(where:  { $0.itemContentID == id })
    }
    
    func isItemOnHowManyLists(id: String) -> Int {
        guard let item = fetch(for: id) else { return 0 }
        return item.listsArray.count
    }
    
    func updateList(for id: String, to list: CustomList) {
        let item = fetch(for: id)
        guard let item else { return }
        if item.itemLists.contains(list) {
            var original = item.itemLists
            original.remove(list)
            let converted = original as NSSet
            item.list = converted
            save()
        } else {
            var set = Set<CustomList>()
            set.insert(list)
            let original = item.itemLists
            for item in original {
                set.insert(item)
            }
            let converted = set as NSSet
            item.list = converted
            save()
        }
    }
    
    func updateListTitle(of list: CustomList, with title: String) {
        list.title = title
        save()
    }
    
    func updateListNotes(of list: CustomList, with notes: String) {
        list.notes = notes
        save()
    }
    
    func updatePinOnHome(of list: CustomList) {
        list.isPin.toggle()
        save()
    }
    
    func addItemsToList(items: Set<WatchlistItem>, list: CustomList) {
        var set = Set<WatchlistItem>()
        set = list.itemsSet
        for item in items {
            set.insert(item)
        }
        list.items = set as NSSet
        save()
    }
    
    /// Remove a set of items from a CustomList.
    /// - Parameters:
    ///   - list: The CustomList that will have items removed from.
    ///   - items: The WatchlistItems to be removed from the given list.
    func removeItemsFromList(of list: CustomList, with items: Set<WatchlistItem>) {
        var set = list.itemsSet
        for item in set {
            if items.contains(item) {
                set.remove(item)
            }
        }
        list.items = set as NSSet
        save()
    }
}
