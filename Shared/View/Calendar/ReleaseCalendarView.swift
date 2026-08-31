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
/// UICalendarView peeks adjacent months when stretched wider than one month (common on iPad / visionOS).
private enum ReleaseCalendarMetrics {
#if os(visionOS)
    /// visionOS UICalendarView needs extra vertical room so the last week / selection ring is not clipped.
    static let maxWidth: CGFloat = 420
    static let minHeight: CGFloat = 460
    static let emptyStateMinHeight: CGFloat = 220
#else
    static let maxWidth: CGFloat = 360
    static let minHeight: CGFloat = 340
    static let emptyStateMinHeight: CGFloat = 160
#endif
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
#if os(visionOS)
        visionOSBody
#else
        listBody
#endif
    }

#if os(visionOS)
    /// List + UICalendarView layout is unreliable in wide visionOS windows; use a centered stack.
    private var visionOSBody: some View {
        ScrollView {
            VStack(spacing: 32) {
                calendarPicker
                    .padding(.top, 8)
                    .padding(.bottom, 8)

                VStack(alignment: .leading, spacing: 12) {
                    Text(releasesSectionTitle)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    releasesContent
                        .frame(maxWidth: .infinity, minHeight: ReleaseCalendarMetrics.emptyStateMinHeight)
                        .padding(24)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Release Calendar")
    }
#endif

    private var listBody: some View {
        List {
            Section {
                calendarPicker
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
            .listRowBackground(Color.clear)

            Section(releasesSectionTitle) {
                releasesContent
            }
        }
#if os(iOS)
        .navigationTitle("Release Calendar")
        .navigationBarTitleDisplayMode(.large)
#else
        .navigationTitle("Release Calendar")
#endif
    }

    @ViewBuilder
    private var releasesContent: some View {
        if upcomingItems.isEmpty {
            emptyUpcomingReleases
        } else if selectedDayItems.isEmpty {
            Text("No watchlist releases on this date.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 80, alignment: .center)
        } else {
            ForEach(selectedDayItems) { item in
                NavigationLink(value: item) {
                    ReleaseCalendarRow(item: item)
                }
            }
        }
    }

    private var emptyUpcomingReleases: some View {
        VStack(spacing: 10) {
            Spacer(minLength: 0)
            Image(systemName: "calendar")
                .font(.system(size: 40, weight: .regular))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("No Upcoming Releases")
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
            Text("Add items with future release dates to your watchlist to see them here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: ReleaseCalendarMetrics.emptyStateMinHeight)
        .accessibilityElement(children: .combine)
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
        HStack {
            Spacer(minLength: 0)
            NativeReleaseCalendarPicker(selectedDate: $selectedDate, releaseDays: releaseDays)
                .frame(width: ReleaseCalendarMetrics.maxWidth)
                .frame(minHeight: ReleaseCalendarMetrics.minHeight)
                // Do not `.clipped()` — visionOS selection rings / last week get cut off.
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
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
        // Keep overflow visible so selection highlights on the last row are not cropped.
        container.clipsToBounds = false
        container.backgroundColor = .clear

        let calendarView = UICalendarView()
        calendarView.calendar = Calendar.current
        calendarView.locale = Locale.current
        calendarView.delegate = context.coordinator
        calendarView.clipsToBounds = false
        calendarView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        calendarView.setContentCompressionResistancePriority(.required, for: .vertical)
        calendarView.setContentHuggingPriority(.required, for: .horizontal)
        calendarView.setContentHuggingPriority(.required, for: .vertical)

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
            calendarView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            calendarView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            calendarView.widthAnchor.constraint(equalToConstant: ReleaseCalendarMetrics.maxWidth)
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
        let fittedWidth = ReleaseCalendarMetrics.maxWidth
        guard let calendarView = context.coordinator.calendarView else {
            return CGSize(width: fittedWidth, height: ReleaseCalendarMetrics.minHeight)
        }
        let size = calendarView.systemLayoutSizeFitting(
            CGSize(width: fittedWidth, height: UIView.layoutFittingExpandedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        // Extra bottom slack for selection rings on the last week.
        let height = max(size.height, ReleaseCalendarMetrics.minHeight) + 12
        return CGSize(width: fittedWidth, height: height)
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
