//
//  CastListView.swift
//  Cronica
//
//  Created by Alexandre Madeira on 29/01/22.
//

import SwiftUI

/// A horizontal list that displays a limited number of
/// cast people in an ItemContent.
struct CastListView: View {
    let credits: [Person]
    var body: some View {
        if !credits.isEmpty {
            VStack(alignment: .leading) {
#if os(tvOS)
                TitleView(title: "Cast & Crew")
                    .padding(.leading, 64)
#else
                NavigationLink(value: credits) {
                    TitleView(title: String(localized: "Cast & Crew"), showChevron: true)
                }
                .buttonStyle(.plain)
#endif
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack {
                        ForEach(credits.prefix(10), id: \.personListID) { person in
                            PersonCardView(person: person)
                                .applyHoverEffect()
                                .padding([.leading, .trailing], 4)
                                .buttonStyle(.plain)
#if os(tvOS)
                                .padding(.leading, person.id == self.credits.first?.id ? 64 : 0)
#else
                                .padding(.leading, person.id == self.credits.first?.id ? 16 : 0)
#endif
                                .padding(.top, 8)
                                .padding(.bottom)
                                .buttonStyle(.plain)
#if os(tvOS)
                                .padding(.vertical)
#endif
                        }
                    }
                    .padding(.bottom)
                    .padding(.top, 8)
                    .padding(.trailing)
                }
            }
#if os(tvOS)
            .padding()
#endif
        }
    }
}

#Preview {
    CastListView(credits: Person.example)
}

private struct DrawingConstants {
    static let profileWidth: CGFloat = 140
    static let profileHeight: CGFloat = 200
    static let shadowRadius: CGFloat = 2
    static let profileRadius: CGFloat = 12
    static let lineLimit: Int = 1
}
