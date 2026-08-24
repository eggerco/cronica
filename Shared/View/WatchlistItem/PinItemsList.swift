//
//  PinItemsList.swift
//  CronicaMac
//
//  Created by Alexandre Madeira on 03/11/22.
//

import SwiftUI

struct PinItemsList: View {
    @FetchRequest(
        sortDescriptors: [ NSSortDescriptor(keyPath: \WatchlistItem.title, ascending: true) ],
        predicate: NSPredicate(format: "isPin == %d", true),
        animation: .default
    ) private var items: FetchedResults<WatchlistItem>
    @Binding var showPopup: Bool
    @Binding var popupType: ActionPopupItems?
    @Binding var shouldReload: Bool
    var body: some View {
        if !items.isEmpty {
            HorizontalWatchlistList(items: items.sorted { $0.itemTitle < $1.itemTitle },
                                    title: NSLocalizedString("Pins", comment: ""),
                                    subtitle: String(),
                                    showPopup: $showPopup,
                                    popupType: $popupType,
                                    shouldReload: $shouldReload)
        }
    }
}

#Preview {
    PinItemsList(showPopup: .constant(false), popupType: .constant(nil), shouldReload: .constant(false))
}
