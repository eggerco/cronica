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
                Label(String(localized: "Up Next"), systemImage: "play.tv")
            }
        }
        .displayName(LocalizedStringResource("Up Next"))
        .description(LocalizedStringResource("Open your Up Next list in Cronica."))
    }
}

@available(iOS 18.0, *)
struct MarkNextEpisodeControl: ControlWidget {
    static let kind = "dev.alexandremadeira.cronica.control.markNextEpisode"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: MarkNextUpNextControlIntent()) {
                Label(String(localized: "Mark Watched"), systemImage: "checkmark.rectangle")
            }
        }
        .displayName(LocalizedStringResource("Mark Up Next"))
        .description(LocalizedStringResource("Mark your next episode as watched."))
    }
}
#endif
