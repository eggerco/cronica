//
//  PersonCardView.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 13/07/22.
//

import SwiftUI
import NukeUI

/// This view is responsible for displaying a given person
/// in a card view, with its name, role, and image.
struct PersonCardView: View {
#if os(tvOS)
    @FocusState var isFocused
#endif
    let person: Person
    @State private var isFavorite: Bool = false
    var body: some View {
#if !os(tvOS)
        NavigationLink(value: person) {
            VStack {
                LazyImage(url: person.personImage) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        ZStack {
                            Rectangle().fill(.gray.gradient)
                            Image(systemName: "person")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50, height: 50, alignment: .center)
                                .foregroundColor(.white)
                            name
                        }
                        .frame(width: DrawingConstants.profileWidth,
                               height: DrawingConstants.profileHeight)
                        .clipShape(RoundedRectangle(cornerRadius: CronicaDesign.Radius.media,
                                                    style: .continuous))
                    }
                }
                .frame(width: DrawingConstants.profileWidth,
                       height: DrawingConstants.profileHeight)
                .clipShape(RoundedRectangle(cornerRadius: CronicaDesign.Radius.media,
                                            style: .continuous))
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 10)
                .overlay {
                    ZStack(alignment: .bottom) {
                        if person.personImage != nil {
                            Color.black.opacity(0.2)
                                .frame(height: 40)
                                .mask {
                                    LinearGradient(colors: [Color.black.opacity(0),
                                                            Color.black.opacity(0.383),
                                                            Color.black.opacity(0.707),
                                                            Color.black.opacity(0.924),
                                                            Color.black],
                                                   startPoint: .top,
                                                   endPoint: .bottom)
                                }
                            Rectangle()
                                .fill(.ultraThinMaterial)
                                .frame(height: 80)
                                .mask {
                                    VStack(spacing: 0) {
                                        LinearGradient(colors: [Color.black.opacity(0),
                                                                Color.black.opacity(0.383),
                                                                Color.black.opacity(0.707),
                                                                Color.black.opacity(0.924),
                                                                Color.black],
                                                       startPoint: .top,
                                                       endPoint: .bottom)
                                        .frame(height: 60)
                                        Rectangle()
                                    }
                                }
                                .environment(\.colorScheme, .dark)
                            name
                        }
                        
                    }
                    .frame(width: DrawingConstants.profileWidth,
                           height: DrawingConstants.profileHeight)
                    .clipShape(RoundedRectangle(cornerRadius: CronicaDesign.Radius.media,
                                                style: .continuous))
                }
                .transition(.opacity)
            }
#if os(iOS) || os(macOS)
            .contextMenu {
                ShareLink(item: person.itemURL)
            }
#endif
        }
#elseif os(tvOS)
        VStack(alignment: .leading) {
            NavigationLink(value: person) {
                LazyImage(url: person.personImage) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        ZStack {
                            Rectangle().fill(.gray.gradient)
                            Image(systemName: "person")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50, height: 50, alignment: .center)
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(width: 200, height: 200, alignment: .center)
                .clipShape(Circle())
                .shadow(radius: 2.5)
            }
            .clipShape(Circle())
            .buttonStyle(.plain)
            .focused($isFocused)
            Text(person.name)
                .foregroundColor(isFocused ? .primary : .secondary)
                .font(.caption)
                .lineLimit(1)
            if let role = person.personRole {
                Text(role)
                    .font(.caption)
                    .foregroundColor(isFocused ? .primary : .secondary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .frame(width: 200)
#endif
    }
    
    private var name: some View {
        VStack {
            Spacer()
            HStack {
                Text(person.name)
                    .font(.callout)
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                    .lineLimit(DrawingConstants.lineLimit)
                    .padding(.leading, 6)
                Spacer()
            }
            HStack {
                Text(person.personRole ?? " ")
                    .foregroundColor(.white)
                    .font(.caption)
                    .lineLimit(DrawingConstants.lineLimit)
                    .padding(.leading, 6)
                Spacer()
            }
        }
        .padding(.bottom)
    }
}

#Preview {
    PersonCardView(person: Person.previewCast)
}

private struct DrawingConstants {
#if os(tvOS)
    static let profileWidth: CGFloat = 240
    static let profileHeight: CGFloat = 360
#else
    static let profileWidth: CGFloat = 140
    static let profileHeight: CGFloat = 200
#endif
    static let shadowRadius: CGFloat = 2.5
    static let lineLimit: Int = 1
}
