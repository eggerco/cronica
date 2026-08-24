//
//  SearchContentUnavailableView.swift
//  Cronica
//

import SwiftUI

struct SearchContentUnavailableView: View {
    let query: String

    var body: some View {
        ContentUnavailableView.search(text: query)
    }
}

struct SimpleUnavailableView: View {
    var title: String = String(localized: "Try again later")
    var systemImage: String = "rectangle.on.rectangle"

    var body: some View {
        ContentUnavailableView(title, systemImage: systemImage)
    }
}
