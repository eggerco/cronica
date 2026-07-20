//
//  PersonSearchImage.swift
//  CronicaMac
//
//  Created by Alexandre Madeira on 20/11/22.
//

import SwiftUI
import NukeUI

/// A rectangular shape for displaying Person images in Search, it is currently used
/// for displaying people in Search for macOS. This is a simpler view from the Cast List.
struct PersonSearchImage: View {
    let item: SearchItemContent
    @FocusState var isStackFocused: Bool
#if os(macOS)
    @State private var isOnHover = false
#endif
    var body: some View {
        VStack(alignment: .leading) {
            PersonSearchImageView(item: item)
#if os(tvOS) || os(macOS)
            HStack {
                Text(item.itemTitle)
                    .padding(.top, 4)
                    .font(.caption)
                    .lineLimit(2)
#if os(tvOS)
                    .foregroundStyle(isStackFocused ? .primary : .secondary)
#elseif os(macOS)
                    .foregroundStyle(isOnHover ? .primary : .secondary)
#endif
                    .frame(maxWidth: DrawingConstants.posterWidth)
                Spacer()
            }
            Spacer()
#endif
        }
#if os(tvOS)
        .focused($isStackFocused)
        .buttonStyle(.card)
#elseif os(macOS)
        .onHover { onHover in
            isOnHover = onHover
        }
#endif
    }
    
    
}

private struct DrawingConstants {
#if os(tvOS)
    static let posterWidth: CGFloat = 260
    static let posterHeight: CGFloat = 380
#else
    static let posterWidth: CGFloat = 160
    static let posterHeight: CGFloat = 240
#endif
    static let shadowRadius: CGFloat = 2.5
}

private struct PersonSearchImageView: View {
    let item: SearchItemContent
    var body: some View {
        NavigationLink(value: item) {
            LazyImage(url: item.itemImage) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    placeholder
                }
            }
            .transition(.opacity)
            .frame(width: DrawingConstants.posterWidth,
                   height: DrawingConstants.posterHeight)
            .clipShape(RoundedRectangle(cornerRadius: CronicaDesign.Radius.media,
                                        style: .continuous))
            .shadow(radius: DrawingConstants.shadowRadius)
            .padding(.zero)
#if os(macOS) || os(iOS)
            .contextMenu { ShareLink(item: item.itemSearchURL) }
#elseif os(tvOS)
            .buttonStyle(.card)
#endif
        }
    }
    
    private var placeholder: some View {
        ZStack {
            Rectangle().fill(.gray.gradient)
            Image(systemName: "person")
                .font(.title)
                .foregroundColor(.secondary)
        }
        .frame(width: DrawingConstants.posterWidth,
               height: DrawingConstants.posterHeight)
        .clipShape(RoundedRectangle(cornerRadius: CronicaDesign.Radius.media,
                                    style: .continuous))
        .shadow(radius: DrawingConstants.shadowRadius)
        .padding(.zero)
    }
}
