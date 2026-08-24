//
//  FavoriteButton.swift
//  Cronica
//
//  Created by Alexandre Madeira on 04/05/23.
//

import SwiftUI

struct FavoriteButton: View {
    let id: String
    @Binding var isFavorite: Bool
    @Binding var popupType: ActionPopupItems?
    @Binding var showPopup: Bool
    var body: some View {
        Button(isFavorite ? "Unfavorite" : "Favorite",
               systemImage: isFavorite ? "heart.slash.fill" : "heart",
               action: updateFavorite)
    }
}

extension FavoriteButton {
    private func updateFavorite() {
        let persistence = PersistenceController.shared
        guard let item = persistence.fetch(for: id) else { return }
        persistence.updateFavorite(for: item)
        withAnimation {
            isFavorite.toggle()
            popupType = isFavorite ? .markedFavorite : .removedFavorite
            showPopup = true
        }
    }
}

#Preview {
    FavoriteButton(id: ItemContent.example.itemContentID,
                   isFavorite: .constant(true),
                   popupType: .constant(nil),
                   showPopup: .constant(false))
}
