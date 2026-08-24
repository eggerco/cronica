//
//  HorizontalPinnedLists.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 26/06/23.
//

import SwiftUI

struct HorizontalPinnedList: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CustomList.title, ascending: true)],
        predicate: NSPredicate(format: "isPin == %d", true),
        animation: .default
    ) private var lists: FetchedResults<CustomList>
    @Binding var showPopup: Bool
    @Binding var popupType: ActionPopupItems?
    @Binding var shouldReload: Bool
    var body: some View {
        if !lists.isEmpty {
            ForEach(lists) { list in
                if !list.itemsSet.isEmpty {
                    HorizontalWatchlistList(items: list.itemsArray,
                                            title: list.itemTitle,
                                            subtitle: list.notes,
                                            showPopup: $showPopup,
                                            popupType: $popupType,
                                            shouldReload: $shouldReload)
                }
            }
        }
    }
}
