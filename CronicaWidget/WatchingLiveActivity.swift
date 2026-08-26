//
//  WatchingLiveActivity.swift
//  CronicaWidget
//

#if os(iOS)
import ActivityKit
import SwiftUI
import WidgetKit
import CronicaCore
import UIKit

struct WatchingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WatchingActivityAttributes.self) { context in
            WatchingLiveActivityLockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.88))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                // Inset from the capsule edge so the poster isn't clipped by the DI corner radius.
                DynamicIslandExpandedRegion(.leading) {
                    WatchingLiveActivityPoster(contentID: context.attributes.contentID)
                        .frame(width: 34, height: 51)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .padding(.leading, 12)
                        .padding(.vertical, 8)
                }

                // Single metric only — remaining lives under the progress bar (avoids truncation).
                DynamicIslandExpandedRegion(.trailing) {
                    WatchingDerivedProgressView(attributes: context.attributes) { progress in
                        Text(WatchingTimeFormatting.short(progress.elapsedMinutes))
                            .font(.subheadline.weight(.semibold).monospacedDigit())
                            .foregroundStyle(.white)
                            .padding(.trailing, 12)
                            .padding(.vertical, 8)
                    }
                }

                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Text(context.state.subtitle)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.65))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    WatchingDerivedProgressView(attributes: context.attributes) { progress in
                        VStack(spacing: 6) {
                            WatchingProgressBar(progress: progress.fraction, height: 3.5)
                            HStack(spacing: 8) {
                                Text(WatchingTimeFormatting.short(progress.elapsedMinutes))
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.white.opacity(0.55))
                                Spacer(minLength: 0)
                                Text(WatchingTimeFormatting.remaining(progress.remainingMinutes))
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.white.opacity(0.55))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.top, 2)
                        .padding(.bottom, 10)
                    }
                }
            } compactLeading: {
                Image(systemName: "play.tv.fill")
                    .font(.body.weight(.semibold))
            } compactTrailing: {
                WatchingDerivedProgressView(attributes: context.attributes) { progress in
                    Text(WatchingTimeFormatting.compact(progress.elapsedMinutes))
                        .font(.caption2.weight(.semibold).monospacedDigit())
                        .minimumScaleFactor(0.7)
                }
            } minimal: {
                Image(systemName: "play.tv.fill")
            }
            .widgetURL(WatchingActivityDeepLink.url(for: context.attributes.contentID))
        }
    }
}

/// Progress is derived in the extension from `startedAt` + `totalMinutes` so it keeps
/// updating while the main app is suspended / the phone is locked.
private struct WatchingDerivedProgressView<Content: View>: View {
    let attributes: WatchingActivityAttributes
    @ViewBuilder let content: (WatchingProgress) -> Content

    var body: some View {
        TimelineView(.periodic(from: attributes.startedAt, by: 60)) { context in
            content(WatchingProgress.compute(attributes: attributes, now: context.date))
        }
    }
}

private struct WatchingProgress {
    let elapsedMinutes: Int
    let remainingMinutes: Int
    let fraction: Double
    let isComplete: Bool

    static func compute(attributes: WatchingActivityAttributes, now: Date) -> WatchingProgress {
        let total = max(attributes.totalMinutes, 0)
        let elapsed = max(0, Int(now.timeIntervalSince(attributes.startedAt) / 60))
        let remaining = max(0, total - elapsed)
        let fraction = total > 0 ? min(1, Double(elapsed) / Double(total)) : 0
        return WatchingProgress(
            elapsedMinutes: min(elapsed, total > 0 ? total : elapsed),
            remainingMinutes: remaining,
            fraction: fraction,
            isComplete: total > 0 && elapsed >= total
        )
    }
}

private struct WatchingLiveActivityLockScreenView: View {
    let context: ActivityViewContext<WatchingActivityAttributes>

    var body: some View {
        WatchingDerivedProgressView(attributes: context.attributes) { progress in
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 14) {
                    WatchingLiveActivityPoster(contentID: context.attributes.contentID)
                        .frame(width: 56, height: 84)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(context.state.title)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.white)
                                .lineLimit(2)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text(WatchingTimeFormatting.short(progress.elapsedMinutes))
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                                .foregroundStyle(.white)
                                .lineLimit(1)
                        }

                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(context.state.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.72))
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text(endsAtLabel)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.white.opacity(0.72))
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        }
                    }
                }

                WatchingProgressBar(progress: progress.fraction, height: 4)

                HStack {
                    Text(
                        progress.isComplete
                            ? String(localized: "Finished")
                            : WatchingTimeFormatting.remaining(progress.remainingMinutes)
                    )
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.72))
                    Spacer(minLength: 0)
                    Text(String(localized: "Cronica"))
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.white.opacity(0.45))
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
        .widgetURL(WatchingActivityDeepLink.url(for: context.attributes.contentID))
    }

    private var endsAtLabel: String {
        let end = context.attributes.startedAt.addingTimeInterval(
            TimeInterval(max(context.attributes.totalMinutes, 0) * 60)
        )
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return String(format: String(localized: "ends %@"), formatter.string(from: end))
    }
}

private enum WatchingTimeFormatting {
    static func compact(_ minutes: Int) -> String {
        let value = max(minutes, 0)
        if value >= 60 {
            return String(format: "%dh%02d", value / 60, value % 60)
        }
        return String(format: "%d min", value)
    }

    static func short(_ minutes: Int) -> String {
        let value = max(minutes, 0)
        let hours = value / 60
        let mins = value % 60
        if hours > 0 {
            return String(format: String(localized: "%dh %dm"), hours, mins)
        }
        return String(format: String(localized: "%d min"), mins)
    }

    static func remaining(_ minutes: Int) -> String {
        String(format: String(localized: "%@ left"), short(minutes))
    }
}

private struct WatchingProgressBar: View {
    let progress: Double
    var height: CGFloat = 4

    var body: some View {
        GeometryReader { geo in
            let clamped = min(max(progress, 0), 1)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.2))
                Capsule()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: max(geo.size.width * clamped, clamped > 0 ? 8 : 0))
            }
        }
        .frame(height: height)
    }
}

private struct WatchingLiveActivityPoster: View {
    let contentID: String

    var body: some View {
        Group {
            if let data = LiveActivityPosterStore.load(contentID: contentID)
                ?? WidgetSnapshotStore.readPoster(named: WidgetSnapshotStore.posterFileName(for: contentID)),
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Color.white.opacity(0.14)
                    Image(systemName: "popcorn.fill")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .overlay {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.5)
        }
    }
}
#endif
