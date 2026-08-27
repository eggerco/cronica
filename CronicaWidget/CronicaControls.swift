//
//  CronicaControls.swift
//  CronicaWidget
//

#if os(iOS)
import AppIntents
import SwiftUI
import WidgetKit

@available(iOS 18.0, *)
struct OpenUpNextControl: ControlWidget {
    static let kind = "dev.alexandremadeira.cronica.control.openUpNext"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: OpenUpNextControlIntent()) {
                Label("Up Next", systemImage: "play.tv")
            }
        }
        .displayName("Up Next")
        .description("Open your Up Next list in Cronica.")
    }
}

@available(iOS 18.0, *)
struct MarkNextEpisodeControl: ControlWidget {
    static let kind = "dev.alexandremadeira.cronica.control.markNextEpisode"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: MarkNextUpNextControlIntent()) {
                Label("Mark Watched", systemImage: "checkmark.rectangle")
            }
        }
        .displayName("Mark Up Next")
        .description("Mark your next episode as watched.")
    }
}
#endif
