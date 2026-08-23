//
//  ItemContentList.swift
//  CronicaWidget
//

import SwiftUI
import CronicaCore

struct ItemContentList: View {
    let rows: [GridItem] = [
        GridItem(.adaptive(minimum: 60))
    ]
    let items: [ItemContent]

    var body: some View {
        VStack {
            if items.isEmpty {
                Text("Trending service isn't available right now.")
                    .font(.callout)
                    .foregroundColor(.secondary)
            } else {
                list
            }
        }
    }

    private var list: some View {
        ViewThatFits {
            HStack(spacing: .zero) {
                ForEach(items) { item in
                    PosterImage(item: item)
                        .frame(width: DrawingConstants.imageWidth,
                               height: DrawingConstants.imageHeight)
                        .shadow(radius: 1)
                        .clipShape(RoundedRectangle(cornerRadius: DrawingConstants.imageRadius, style: .continuous))
                        .padding(.leading, item.id == items.first?.id ? 0 : 6)
                }
            }
            HStack {
                ForEach(items) { item in
                    PosterImage(item: item)
                        .frame(width: DrawingConstants.smallImageWidth,
                               height: DrawingConstants.smallImageHeight)
                        .clipShape(RoundedRectangle(cornerRadius: DrawingConstants.imageRadius, style: .continuous))
                        .padding(.leading, item.id == items.first?.id ? 0 : 4)
                }
            }
        }
    }
}

private struct PosterImage: View {
    let item: ItemContent

    var body: some View {
        Group {
            if let destination = URL(string: item.itemContentID) {
                Link(destination: destination) {
                    posterContent
                }
            } else {
                posterContent
            }
        }
    }

    @ViewBuilder
    private var posterContent: some View {
        if let placeholder = item.placeholderImagePath {
            Image(placeholder)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else if let image = item.widgetImageData {
#if os(iOS)
            Image(uiImage: UIImage(data: image) ?? UIImage(systemName: "popcorn") ?? UIImage())
                .resizable()
#elseif os(macOS)
            if let nsImage = NSImage(data: image) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "popcorn")
            }
#endif
        } else {
            PlaceholderImage()
        }
    }
}

private struct PlaceholderImage: View {
    var body: some View {
        ZStack {
            Rectangle().fill(Color.gray.gradient)
            Image(systemName: "popcorn")
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

private struct DrawingConstants {
    static let imageWidth: CGFloat = 74
    static let imageHeight: CGFloat = 130
    static let smallImageWidth: CGFloat = 68
    static let smallImageHeight: CGFloat = 110
    static let imageRadius: CGFloat = 6
}
