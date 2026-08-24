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

    @State private var displayedMonth = Date()
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

    private var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let gridStart = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start)?.start
        else { return [] }

        return (0..<42).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: gridStart)
                .map { calendar.startOfDay(for: $0) }
        }
    }

    private var selectedDayItems: [WatchlistItem] {
        (itemsByDay[selectedDate] ?? []).sorted { $0.itemTitle.localizedCaseInsensitiveCompare($1.itemTitle) == .orderedAscending }
    }

    var body: some View {
        List {
            Section {
                monthHeader
                weekdayHeader
                calendarGrid
            }

            Section("Releases") {
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

    private var monthHeader: some View {
        HStack {
            Button {
                displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)

            Spacer()

            Text(displayedMonth, format: .dateTime.month(.wide).year())
                .font(.headline)

            Spacer()

            Button {
                displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    private var weekdayHeader: some View {
        let symbols = calendar.shortWeekdaySymbols
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(symbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var calendarGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(daysInMonth, id: \.self) { day in
                dayCell(for: day)
            }
        }
    }

    private func dayCell(for day: Date) -> some View {
        let isInDisplayedMonth = calendar.isDate(day, equalTo: displayedMonth, toGranularity: .month)
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
        let hasRelease = itemsByDay[day] != nil

        return Button {
            selectedDate = day
        } label: {
            VStack(spacing: 4) {
                Text(day, format: .dateTime.day())
                    .font(.body)
                    .foregroundStyle(isInDisplayedMonth ? Color.primary : Color.secondary.opacity(0.4))
                Circle()
                    .fill(hasRelease ? Color.accentColor : Color.clear)
                    .frame(width: 5, height: 5)
            }
            .frame(maxWidth: .infinity, minHeight: 36)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.accentColor.opacity(0.15))
                }
            }
        }
        .buttonStyle(.plain)
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
