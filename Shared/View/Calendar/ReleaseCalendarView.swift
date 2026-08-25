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
/// UICalendarView peeks adjacent months when stretched wider than one month (common on iPad).
private enum ReleaseCalendarMetrics {
    static let maxWidth: CGFloat = 360
    static let minHeight: CGFloat = 340
}

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
            .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
            .listRowBackground(Color.clear)

            Section(releasesSectionTitle) {
                if upcomingItems.isEmpty {
                    ContentUnavailableView {
                        Label("No Upcoming Releases", systemImage: "calendar")
                    } description: {
                        Text("Add items with future release dates to your watchlist to see them here.")
                            .foregroundStyle(.secondary)
                    }
                } else if selectedDayItems.isEmpty {
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
#if os(iOS)
        .navigationTitle("Release Calendar")
        .navigationBarTitleDisplayMode(.large)
#else
        .navigationTitle("Release Calendar")
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
            .frame(maxWidth: ReleaseCalendarMetrics.maxWidth)
            .frame(maxWidth: .infinity, alignment: .center)
            .frame(minHeight: ReleaseCalendarMetrics.minHeight)
            .clipped()
#else
        DatePicker(
            "Release Date",
            selection: $selectedDate,
            displayedComponents: [.date]
        )
        .datePickerStyle(.graphical)
        .labelsHidden()
        .frame(maxWidth: ReleaseCalendarMetrics.maxWidth)
        .frame(maxWidth: .infinity, alignment: .center)
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

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.clipsToBounds = true
        container.backgroundColor = .clear

        let calendarView = UICalendarView()
        calendarView.calendar = Calendar.current
        calendarView.locale = Locale.current
        calendarView.delegate = context.coordinator
        calendarView.clipsToBounds = true
        calendarView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        calendarView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        calendarView.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        let selection = UICalendarSelectionSingleDate(delegate: context.coordinator)
        calendarView.selectionBehavior = selection
        context.coordinator.selection = selection
        context.coordinator.calendarView = calendarView
        selection.selectedDate = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)

        calendarView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(calendarView)
        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: container.topAnchor),
            calendarView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            calendarView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            calendarView.widthAnchor.constraint(lessThanOrEqualToConstant: ReleaseCalendarMetrics.maxWidth),
            calendarView.widthAnchor.constraint(lessThanOrEqualTo: container.widthAnchor),
            calendarView.widthAnchor.constraint(equalTo: container.widthAnchor).withPriority(.defaultHigh)
        ])

        return container
    }

    func updateUIView(_ container: UIView, context: Context) {
        context.coordinator.releaseDays = releaseDays
        guard let calendarView = context.coordinator.calendarView else { return }

        let selectedComponents = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
        if context.coordinator.selection?.selectedDate != selectedComponents {
            context.coordinator.selection?.selectedDate = selectedComponents
        }

        let decorationComponents = releaseDays.map {
            Calendar.current.dateComponents([.year, .month, .day], from: $0)
        }
        calendarView.reloadDecorations(forDateComponents: decorationComponents, animated: false)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIView, context: Context) -> CGSize? {
        guard let width = proposal.width else { return nil }
        let fittedWidth = min(width, ReleaseCalendarMetrics.maxWidth)
        guard let calendarView = context.coordinator.calendarView else {
            return CGSize(width: fittedWidth, height: ReleaseCalendarMetrics.minHeight)
        }
        let size = calendarView.systemLayoutSizeFitting(
            CGSize(width: fittedWidth, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        return CGSize(width: width, height: max(size.height, ReleaseCalendarMetrics.minHeight))
    }

    final class Coordinator: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
        @Binding var selectedDate: Date
        var releaseDays: Set<Date>
        weak var selection: UICalendarSelectionSingleDate?
        weak var calendarView: UICalendarView?

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

private extension NSLayoutConstraint {
    func withPriority(_ priority: UILayoutPriority) -> NSLayoutConstraint {
        self.priority = priority
        return self
    }
}
#endif

private struct ReleaseCalendarRow: View {
    let item: WatchlistItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.itemTitle)
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
