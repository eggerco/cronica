//
//  WatchStatisticsView.swift
//  Cronica
//

import SwiftUI

struct WatchStatisticsView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WatchlistItem.title, ascending: true)],
        animation: .default
    ) private var items: FetchedResults<WatchlistItem>
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WatchlistItem.title, ascending: true)],
        predicate: NSPredicate(format: "hideFromWatchlist == %d", true),
        animation: .default
    ) private var hiddenItems: FetchedResults<WatchlistItem>

    private var stats: WatchStatistics {
        WatchStatistics.compute(from: Array(items))
    }

    var body: some View {
        Form {
            Section {
                LabeledContent("Watched titles", value: "\(stats.watchedCount)")
                LabeledContent("Estimated time", value: stats.estimatedHoursText)
                LabeledContent("Last 7 days", value: "\(stats.watchedLast7Days)")
                LabeledContent("Last 30 days", value: "\(stats.watchedLast30Days)")
            } header: {
                Text("Local Watch Statistics")
            } footer: {
                Text("Based on titles marked watched on this device. Estimated time uses stored runtimes when available; TV estimates multiply watched episodes by average episode length.")
            }

            if !hiddenItems.isEmpty {
                Section {
                    ForEach(hiddenItems) { item in
                        HStack {
                            Text(item.itemTitle)
                            Spacer()
                            Button("Unhide") {
                                PersistenceController.shared.updateHideFromWatchlist(for: item, hidden: false)
                            }
#if os(macOS)
                            .buttonStyle(.link)
#endif
                        }
                    }
                } header: {
                    Text("Hidden from Watchlist")
                } footer: {
                    Text("These titles stay off your main Watchlist until you unhide them.")
                }
            }
        }
        .navigationTitle("Watch Statistics")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .scrollBounceBehavior(.basedOnSize, axes: .vertical)
#endif
#if os(macOS)
        .formStyle(.grouped)
#endif
    }
}

#Preview {
    NavigationStack {
        WatchStatisticsView()
    }
}
