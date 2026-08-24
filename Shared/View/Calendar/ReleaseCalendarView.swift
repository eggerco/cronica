//
//  ReleaseCalendarView.swift
//  Cronica
//

import SwiftUI
import CoreData

#if !os(watchOS)
struct ReleaseCalendarView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WatchlistItem.date, ascending: true)],
        predicate: NSPredicate(format: "isArchive == NO"),
        animation: .default
    )
    private var items: FetchedResults<WatchlistItem>

    @State private var selectedDate = Calendar.current.startOfDay(for: Date())

    private var calendar: Calendar { Calendar.current }

    private var upcomingItems: [WatchlistItem] {
        items.filter { item in
            guard let day = calendarDay(for: item) else { return false }
            return day >= calendar.startOfDay(for: Date())
        }
    }

    private var itemsByDay: [Date: [WatchlistItem]] {
        Dictionary(grouping: upcomingItems) { item in
            calendarDay(for: item) ?? Date.distantPast
        }
    }

    private var selectedDay: Date {
        calendar.startOfDay(for: selectedDate)
    }

    private var selectedDayItems: [WatchlistItem] {
        (itemsByDay[selectedDay] ?? []).sorted {
            $0.itemTitle.localizedCaseInsensitiveCompare($1.itemTitle) == .orderedAscending
        }
    }

    var body: some View {
        List {
            Section {
                DatePicker(
                    "Release Date",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .onChange(of: selectedDate) { _, newValue in
                    let day = calendar.startOfDay(for: newValue)
                    if day != selectedDate {
                        selectedDate = day
                    }
                }
            }
            .listRowInsets(EdgeInsets())

            CronicaFormSection("Releases") {
                if selectedDayItems.isEmpty {
                    Text("No watchlist releases on this date.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(selectedDayItems) { item in
                        NavigationLink(value: item) {
                            ReleaseCalendarRow(item: item)
                        }
                    }
                }
            }
        }
        .navigationTitle("Release Calendar")
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
        .cronicaSettingsForm()
        .cronicaWatchlistNavigationDestinations()
    }

    private func calendarDay(for item: WatchlistItem) -> Date? {
        let date = item.itemUpcomingReleaseDate
        guard date != Date.distantPast else { return nil }
        return calendar.startOfDay(for: date)
    }
}

private struct ReleaseCalendarRow: View {
    let item: WatchlistItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.itemTitle)
                .font(.body)
            if let info = item.itemGlanceInfo {
                Text(info)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        ReleaseCalendarView()
    }
}
#endif
