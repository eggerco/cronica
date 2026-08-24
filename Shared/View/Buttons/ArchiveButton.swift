//
//  ArchiveButton.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 04/05/23.
//

import SwiftUI

struct ArchiveButton: View {
    let id: String
    @Binding var isArchive: Bool
    @Binding var popupType: ActionPopupItems?
    @Binding var showPopup: Bool
    private let persistence = PersistenceController.shared
    var body: some View {
        Button(isArchive ? "Unarchive" : "Archive",
               systemImage: isArchive ? "archivebox.fill" : "archivebox",
               action: updateArchive)
    }
    
    private func updateArchive() {
        guard let item = persistence.fetch(for: id) else { return }
        persistence.updateArchive(for: item)
        withAnimation { isArchive.toggle() }
        if isArchive {
            NotificationManager.shared.removeNotification(identifier: id)
        }
#if !os(watchOS)
        popupType = isArchive ? .markedArchive : .removedArchive
        withAnimation { showPopup = true }
#endif
    }
}

#Preview {
    ArchiveButton(id: ItemContent.example.itemContentID,
                  isArchive: .constant(false),
                  popupType: .constant(nil),
                  showPopup: .constant(true))
}
