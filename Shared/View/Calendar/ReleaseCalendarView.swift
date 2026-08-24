//
//  ReleaseCalendarView.swift
//  Cronica
//

import SwiftUI
import CoreData
#if canImport(UIKit)
import UIKit
#endif

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

    private var releaseDays: Set<Date> {
        Set(itemsByDay.keys.filter { $0 != Date.distantPast })
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
                calendarPicker
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
            .listRowBackground(Color.clear)

            CronicaListSection(releasesSectionTitle) {
                if upcomingItems.isEmpty {
                    ContentUnavailableView {
                        Label {
                            CronicaFormText("No Upcoming Releases")
                        } icon: {
                            Image(systemName: "calendar")
                        }
                    } description: {
                        CronicaFormText(
                            "Add items with future release dates to your watchlist to see them here.",
                            color: .secondary
                        )
                    }
                } else if selectedDayItems.isEmpty {
                    CronicaFormText("No watchlist releases on this date.", color: .secondary)
                } else {
                    ForEach(selectedDayItems) { item in
                        NavigationLink(value: item) {
                            ReleaseCalendarRow(item: item)
                        }
                    }
                }
            }
        }
        .cronicaNormalTextCase()
#if os(iOS)
        .cronicaNavigationTitle("Release Calendar", displayMode: .large)
#else
        .cronicaNavigationTitle("Release Calendar")
#endif
    }

    private var releasesSectionTitle: String {
        if selectedDayItems.isEmpty {
            return "Releases"
        }
        return "Releases (\(selectedDayItems.count))"
    }

    @ViewBuilder
    private var calendarPicker: some View {
#if canImport(UIKit) && !os(tvOS)
        NativeReleaseCalendarPicker(selectedDate: $selectedDate, releaseDays: releaseDays)
            .frame(minHeight: 320)
#else
        DatePicker(
            "Release Date",
            selection: $selectedDate,
            displayedComponents: [.date]
        )
        .datePickerStyle(.graphical)
        .labelsHidden()
#endif
    }

    private func calendarDay(for item: WatchlistItem) -> Date? {
        let date = item.itemUpcomingReleaseDate
        guard date != Date.distantPast else { return nil }
        return calendar.startOfDay(for: date)
    }
}

#if canImport(UIKit) && !os(tvOS)
private struct NativeReleaseCalendarPicker: UIViewRepresentable {
    @Binding var selectedDate: Date
    var releaseDays: Set<Date>

    func makeCoordinator() -> Coordinator {
        Coordinator(selectedDate: $selectedDate, releaseDays: releaseDays)
    }

    func makeUIView(context: Context) -> UICalendarView {
        let calendarView = UICalendarView()
        calendarView.calendar = Calendar.current
        calendarView.locale = Locale.current
        calendarView.delegate = context.coordinator
        calendarView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        calendarView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        let selection = UICalendarSelectionSingleDate(delegate: context.coordinator)
        calendarView.selectionBehavior = selection
        context.coordinator.selection = selection
        selection.selectedDate = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)

        return calendarView
    }

    func updateUIView(_ calendarView: UICalendarView, context: Context) {
        context.coordinator.releaseDays = releaseDays

        let selectedComponents = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
        if context.coordinator.selection?.selectedDate != selectedComponents {
            context.coordinator.selection?.selectedDate = selectedComponents
        }

        let decorationComponents = releaseDays.map {
            Calendar.current.dateComponents([.year, .month, .day], from: $0)
        }
        calendarView.reloadDecorations(forDateComponents: decorationComponents, animated: false)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UICalendarView, context: Context) -> CGSize? {
        guard let width = proposal.width else { return nil }
        let size = uiView.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        return size
    }

    final class Coordinator: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
        @Binding var selectedDate: Date
        var releaseDays: Set<Date>
        weak var selection: UICalendarSelectionSingleDate?

        init(selectedDate: Binding<Date>, releaseDays: Set<Date>) {
            _selectedDate = selectedDate
            self.releaseDays = releaseDays
        }

        func dateSelection(
            _ selection: UICalendarSelectionSingleDate,
            didSelectDate dateComponents: DateComponents?
        ) {
            guard let dateComponents,
                  let date = Calendar.current.date(from: dateComponents) else { return }
            selectedDate = Calendar.current.startOfDay(for: date)
        }

        func calendarView(
            _ calendarView: UICalendarView,
            decorationFor dateComponents: DateComponents
        ) -> UICalendarView.Decoration? {
            guard let date = Calendar.current.date(from: dateComponents) else { return nil }
            let day = Calendar.current.startOfDay(for: date)
            guard releaseDays.contains(day) else { return nil }
            return .default(color: UIColor.tintColor, size: .small)
        }
    }
}
#endif

private struct ReleaseCalendarRow: View {
    let item: WatchlistItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            CronicaFormText(item.itemTitle)
            if let info = item.itemGlanceInfo {
                CronicaFormText(info, font: .caption, color: .secondary)
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
