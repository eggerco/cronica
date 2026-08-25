//
//  InfoSegmentView.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 05/05/23.
//

import SwiftUI

struct InfoSegmentView: View {
    let title: String
    let info: String?
    var body: some View {
        if let info {
            VStack(alignment: .leading) {
                Text(title)
                    .lineLimit(1)
                    .font(.body)
                    .foregroundColor(.secondary)
                Text(info)
                    .lineLimit(1)
                    .font(.body)
            }
        }
    }
}

#Preview {
    InfoSegmentView(title: "This is for Preview", info: "SwiftUI Previews!")
}
