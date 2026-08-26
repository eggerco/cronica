//
//  ShareExtensionView.swift
//  Cronica Share Extension
//

import SwiftUI
import UniformTypeIdentifiers
import CronicaCore

struct ShareExtensionView: View {
    enum Phase: Equatable {
        case loading
        case added(ItemContent)
        case alreadyOnWatchlist
        case unsupportedURL
        case notFound
        case fetchFailed
    }

    let extensionContext: NSExtensionContext?
    let onComplete: () -> Void

    @State private var phase: Phase = .loading

    var body: some View {
        NavigationStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
                .navigationTitle(String(localized: "Add to Cronica"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(String(localized: "Cancel"), action: onComplete)
                    }
                }
        }
        .task {
            await processSharedContent()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .loading:
            VStack(spacing: 16) {
                ProgressView()
                Text(String(localized: "Adding to your watchlist…"))
                    .foregroundStyle(.secondary)
            }
        case .added(let item):
            resultView(
                systemImage: "checkmark.circle.fill",
                tint: .green,
                title: String(localized: "Added to Watchlist"),
                message: item.itemTitle
            )
        case .alreadyOnWatchlist:
            resultView(
                systemImage: "bookmark.fill",
                tint: .orange,
                title: String(localized: "Already on Watchlist"),
                message: String(localized: "This title is already in Cronica.")
            )
        case .unsupportedURL:
            resultView(
                systemImage: "exclamationmark.triangle.fill",
                tint: .yellow,
                title: String(localized: "Unsupported Link"),
                message: String(localized: "Share a link from IMDb, Letterboxd, Rotten Tomatoes, Trakt, JustWatch, TMDb, or Cronica.")
            )
        case .notFound:
            resultView(
                systemImage: "magnifyingglass",
                tint: .orange,
                title: String(localized: "Title Not Found"),
                message: String(localized: "Cronica couldn't match this link to a movie or TV show.")
            )
        case .fetchFailed:
            resultView(
                systemImage: "wifi.exclamationmark",
                tint: .red,
                title: String(localized: "Couldn’t Add Title"),
                message: String(localized: "Check your connection and try again.")
            )
        }
    }

    private func resultView(systemImage: String, tint: Color, title: String, message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: systemImage)
                .font(.system(size: 44))
                .foregroundStyle(tint)

            VStack(spacing: 8) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(String(localized: "Done"), action: onComplete)
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
        }
    }

    @MainActor
    private func processSharedContent() async {
        guard let url = await SharedURLExtractor.url(from: extensionContext) else {
            phase = .unsupportedURL
            return
        }

        switch await WatchlistAddService.add(from: url) {
        case .added(let content):
            phase = .added(content)
        case .alreadyOnWatchlist:
            phase = .alreadyOnWatchlist
        case .unsupportedURL:
            phase = .unsupportedURL
        case .notFound:
            phase = .notFound
        case .fetchFailed:
            phase = .fetchFailed
        }
    }
}

private enum SharedURLExtractor {
    static func url(from context: NSExtensionContext?) async -> URL? {
        guard let items = context?.inputItems as? [NSExtensionItem] else { return nil }

        for item in items {
            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier),
                   let item = try? await provider.loadItem(forTypeIdentifier: UTType.url.identifier),
                   let url = item as? URL {
                    return url
                }

                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier),
                   let item = try? await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier),
                   let text = item as? String,
                   let url = URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines)),
                   MediaURLResolver.parse(url) != nil {
                    return url
                }
            }
        }

        return nil
    }
}
