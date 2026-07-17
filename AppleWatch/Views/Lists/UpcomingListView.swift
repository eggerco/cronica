//
//  UpcomingListView.swift
//  Cronica Watch App
//
//  Created by Alexandre Madeira on 18/07/23.
//

import SwiftUI
import NukeUI

struct UpcomingListView: View {
    static let tag: Screens? = .upcoming
    @FetchRequest(
        entity: WatchlistItem.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \WatchlistItem.date, ascending: true),
        ],
        predicate: NSCompoundPredicate(type: .or, subpredicates: [
            NSCompoundPredicate(type: .and,
                                subpredicates: [
                                    NSPredicate(format: "schedule == %d", ItemSchedule.soon.toInt),
                                    NSPredicate(format: "notify == %d", true),
                                    NSPredicate(format: "contentType == %d", MediaType.movie.toInt)
                                ])
            ,
            NSPredicate(format: "upcomingSeason == %d", true)])
    )
    var items: FetchedResults<WatchlistItem>
    var body: some View {
        NavigationStack {
            list(items: items.filter { $0.backCompatibleCardImage != nil && $0.itemUpcomingReleaseDate > Date() && !$0.isArchive }.sorted(by: { $0.itemUpcomingReleaseDate < $1.itemUpcomingReleaseDate}))
        }
    }
    
    private func list(items: [WatchlistItem]) -> some View {
        VStack {
            if !items.isEmpty {
                List {
                    ForEach(items) { item in
                        NavigationLink(value: item) {
                            itemRow(item)
                        }
                    }
                }
            } else {
                ContentUnavailableView("Your upcoming items will appear here.",
                                       systemImage: "popcorn")
            }
        }
        .navigationTitle("Upcoming")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: WatchlistItem.self) { item in
            ItemContentView(id: item.itemId,
                            title: item.itemTitle,
                            type: item.itemMedia,
                            image: item.backCompatibleCardImage)
        }
    }
    
    private func itemRow(_ item: WatchlistItem) -> some View {
        HStack(spacing: CronicaDesign.Spacing.sm) {
            LazyImage(url: item.backCompatibleCardImage) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    ZStack {
                        Rectangle().fill(.gray.gradient)
                        Image(systemName: "popcorn")
                            .fontWidth(.expanded)
                            .foregroundColor(.white.opacity(0.8))
                            .padding([.horizontal, .bottom])
                    }
                    .unredacted()
                    .frame(width: DrawingConstants.imageWidth,
                           height: DrawingConstants.imageHeight)
                }
            }
            .transition(.opacity)
            .frame(width: DrawingConstants.imageWidth,
                   height: DrawingConstants.imageHeight)
            .clipShape(RoundedRectangle(cornerRadius: CronicaDesign.Radius.media, style: .continuous))
            VStack(alignment: .leading, spacing: CronicaDesign.Spacing.xxs) {
                Text(item.itemTitle)
                    .font(CronicaDesign.Typography.caption())
                    .lineLimit(2)
                Text(item.itemGlanceInfo ?? String())
                    .font(CronicaDesign.Typography.caption())
                    .textCase(.uppercase)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            Spacer()
        }
    }
}

#Preview {
    UpcomingListView()
}

private struct DrawingConstants {
    static let imageWidth: CGFloat = 70
    static let imageHeight: CGFloat = 50
}
