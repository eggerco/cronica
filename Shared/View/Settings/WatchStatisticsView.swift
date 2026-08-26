//
//  WatchStatisticsView.swift
//  Cronica
//

import SwiftUI
import Charts

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
            if !stats.mediaBreakdown.isEmpty {
                Section {
                    Chart(stats.mediaBreakdown) { slice in
                        SectorMark(
                            angle: .value("Titles", slice.count),
                            innerRadius: .ratio(0.55),
                            angularInset: 1.5
                        )
                        .foregroundStyle(by: .value("Type", slice.label))
                        .cornerRadius(4)
                    }
                    .chartForegroundStyleScale([
                        String(localized: "Movies"): Color.blue,
                        String(localized: "TV Shows"): Color.purple,
                    ])
                    .frame(minHeight: 200)

                    ForEach(stats.mediaBreakdown) { slice in
                        LabeledContent(slice.label) {
                            Text("\(slice.count) · \(WatchStatistics.formatMinutes(slice.estimatedMinutes))")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Movies vs TV")
                } footer: {
                    Text("Watched titles grouped by type, with estimated viewing time.")
                }
            }

            Section {
                Chart(stats.weeklyActivity) { week in
                    BarMark(
                        x: .value("Week", week.axisLabel),
                        y: .value("Watched", week.count)
                    )
                    .foregroundStyle(.green.gradient)
                    .cornerRadius(4)
                }
                .chartYAxis {
                    AxisMarks(preset: .aligned, position: .leading)
                }
                .frame(minHeight: 180)
            } header: {
                Text("Watched per week")
            } footer: {
                Text("Titles marked watched in the last eight weeks.")
            }

            Section {
                Chart(stats.weeklyHours) { week in
                    BarMark(
                        x: .value("Week", week.axisLabel),
                        y: .value("Hours", week.hours)
                    )
                    .foregroundStyle(.orange.gradient)
                    .cornerRadius(4)
                }
                .chartYAxis {
                    AxisMarks(preset: .aligned, position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let hours = value.as(Double.self) {
                                Text(hours, format: .number.precision(.fractionLength(0...1)))
                            }
                        }
                    }
                }
                .frame(minHeight: 180)
            } header: {
                Text("Estimated hours per week")
            } footer: {
                Text("Estimated viewing time for titles marked watched each week.")
            }

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
