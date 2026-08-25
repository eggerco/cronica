//
//  HideFromWatchlistButton.swift
//  Cronica
//

import SwiftUI

struct HideFromWatchlistButton: View {
    let id: String
    @Binding var isHidden: Bool
    private let persistence = PersistenceController.shared

    var body: some View {
        Button(isHidden ? "Unhide from Watchlist" : "Hide from Watchlist",
               systemImage: isHidden ? "eye" : "eye.slash",
               action: updateHidden)
    }

    private func updateHidden() {
        guard let item = persistence.fetch(for: id) else { return }
        let willHide = !isHidden
        persistence.updateHideFromWatchlist(for: item, hidden: willHide)
        withAnimation { isHidden = willHide }
    }
}

#Preview {
    HideFromWatchlistButton(id: ItemContent.example.itemContentID, isHidden: .constant(false))
}
