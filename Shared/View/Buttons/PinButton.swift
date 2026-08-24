//
//  PinButton.swift
//  Cronica
//
//  Created by Alexandre Madeira on 04/05/23.
//

import SwiftUI

struct PinButton: View {
    let id: String
    @Binding var isPin: Bool
    @Binding var popupType: ActionPopupItems?
    @Binding var showPopup: Bool
    private let persistence = PersistenceController.shared
    var body: some View {
        Button(isPin ? "Unpin" : "Pin",
               systemImage: isPin ? "pin.fill" : "pin",
               action: updatePin)
    }
}

extension PinButton {
    private func updatePin() {
        guard let item = persistence.fetch(for: id) else { return }
        persistence.updatePin(for: item)
        withAnimation {
            isPin.toggle()
            popupType = isPin ? .markedPin : .removedPin
            showPopup = true
        }
    }
}

#Preview {
    PinButton(id: ItemContent.example.itemContentID,
              isPin: .constant(false),
              popupType: .constant(nil),
              showPopup: .constant(false))
}
