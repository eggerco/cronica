//
//  HideFromUpNextButton.swift
//  Cronica
//

import SwiftUI

struct HideFromUpNextButton: View {
    let id: String
    @Binding var isHidden: Bool
    private let persistence = PersistenceController.shared

    var body: some View {
        Button(isHidden ? "Show in Up Next" : "Hide from Up Next",
               systemImage: isHidden ? "eye" : "eye.slash",
               action: updateHidden)
    }

    private func updateHidden() {
        guard let item = persistence.fetch(for: id), item.isTvShow else { return }
        let willHide = !isHidden
        persistence.updateHideFromUpNext(for: item, hidden: willHide)
        withAnimation { isHidden = willHide }
    }
}

#Preview {
    HideFromUpNextButton(id: ItemContent.example.itemContentID, isHidden: .constant(false))
}
