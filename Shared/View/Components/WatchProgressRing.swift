//
//  WatchProgressRing.swift
//  Cronica
//

import SwiftUI

/// Compact circular progress for TV shows (0...1).
struct WatchProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 3
    var size: CGFloat = 22

    private var clamped: Double {
        min(1, max(0, progress))
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.25), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if clamped > 0 {
                Text("\(Int((clamped * 100).rounded()))")
                    .font(.system(size: size * 0.32, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .minimumScaleFactor(0.5)
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel(Text(String(format: String(localized: "%d%% watched"), Int((clamped * 100).rounded()))))
    }
}

#Preview {
    HStack {
        WatchProgressRing(progress: 0.35)
        WatchProgressRing(progress: 0.8, size: 28)
    }
    .padding()
}
