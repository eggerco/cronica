//
//  AboutSectionView.swift
//  Cronica Watch App
//
//  Created by Alexandre Madeira on 29/09/22.
//

import SwiftUI

struct AboutSectionView: View {
    let about: String?
	@State private var showAbout = false
    var body: some View {
        if let about {
            if !about.isEmpty {
                Section {
                    VStack(alignment: .leading) {
                        Text(about)
							.lineLimit(showAbout ? nil : 4)
                    }
					.onTapGesture {
						withAnimation { showAbout.toggle() }
					}
					.padding(.zero)
                } header: {
                    HStack {
                        Text("About")
							.foregroundColor(.secondary)
                        Spacer()
                    }
					.padding([.horizontal, .top])
                }
				.padding([.horizontal, .bottom])
            }
        }
    }
}


#Preview {
    AboutSectionView(about: ItemContent.example.itemOverview)
}
