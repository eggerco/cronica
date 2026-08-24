//
//  View-Extensions.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 20/12/22.
//

import SwiftUI

extension View {
    /// This function is responsible for creating an action popup in SwiftUI.
    /// - Parameters:
    ///   - isShowing: A binding to a Boolean value that determines whether the action popup is currently being shown or not.
    ///   - item: An optional ActionPopupItems value representing the specific action item associated with the popup.
    /// - Returns: The function applies the ConfirmationPopupModifier view modifier to the content view that is passed as an argument. The modifier configures the overlay and behavior of the action popup.
    func actionPopup(isShowing: Binding<Bool>, for item: ActionPopupItems?) -> some View {
        modifier(ConfirmationPopupModifier(isShowing: isShowing, item: item))
    }
    func watchlistContextMenu(item: WatchlistItem,
                              isWatched: Binding<Bool>,
                              isFavorite: Binding<Bool>,
                              isPin: Binding<Bool>,
                              isArchive: Binding<Bool>,
                              showNote: Binding<Bool>,
                              showCustomList: Binding<Bool>,
                              popupType: Binding<ActionPopupItems?>,
                              showPopup: Binding<Bool>) -> some View {
        modifier(WatchlistItemContextMenu(item: item,
                                          isWatched: isWatched,
                                          isFavorite: isFavorite,
                                          isPin: isPin,
                                          isArchive: isArchive,
                                          showNote: showNote,
                                          showCustomListView: showCustomList,
                                          popupType: popupType,
                                          showPopup: showPopup))
    }
    
    func itemContentContextMenu(item: ItemContent,
                                isWatched: Binding<Bool>,
                                showPopup: Binding<Bool>,
                                isInWatchlist: Binding<Bool>,
                                showNote: Binding<Bool>,
                                showCustomList: Binding<Bool>,
                                popupType: Binding<ActionPopupItems?>,
                                isFavorite: Binding<Bool>,
                                isPin: Binding<Bool>,
                                isArchive: Binding<Bool>) -> some View {
        modifier(ItemContentContextMenu(item: item,
                                        showPopup: showPopup,
                                        isInWatchlist: isInWatchlist,
                                        isWatched: isWatched,
                                        isFavorite: isFavorite,
                                        isPin: isPin,
                                        isArchive: isArchive,
                                        showNote: showNote,
                                        showCustomListView: showCustomList,
                                        popupType: popupType))
    }
    
    func searchItemContextMenu(item: SearchItemContent,
                               showPopup: Binding<Bool>,
                               isInWatchlist: Binding<Bool>,
                               isWatched: Binding<Bool>,
                               showNote: Binding<Bool>,
                               showCustomList: Binding<Bool>,
                               popupType: Binding<ActionPopupItems?>) -> some View {
        modifier(SearchItemContentContextMenu(item: item,
                                              showPopup: showPopup,
                                              isInWatchlist: isInWatchlist,
                                              isWatched: isWatched,
                                              showNote: showNote,
                                              showCustomListView: showCustomList,
                                              popupType: popupType))
    }
    
    func applyHoverEffect() -> some View {
        modifier(HoverEffectModifier())
    }

    /// Prevents SwiftUI Form/navigation from force-uppercasing row labels (`.textCase(.none)` is a no-op).
    func cronicaNormalTextCase() -> some View {
        environment(\.textCase, nil)
    }

    /// Standard settings form styling: sentence-case rows/footers, uppercase section headers via `CronicaFormSection`.
    func cronicaSettingsForm() -> some View {
        cronicaNormalTextCase()
#if os(iOS)
            .scrollBounceBehavior(.basedOnSize, axes: .vertical)
#endif
#if os(macOS)
            .formStyle(.grouped)
#endif
    }

    /// Keeps authored casing on navigation titles (Lists can force uppercase large titles).
    func cronicaNavigationTitle(
        _ title: String,
        displayMode: NavigationBarItem.TitleDisplayMode = .automatic
    ) -> some View {
        modifier(CronicaNavigationTitleModifier(title: title, displayMode: displayMode))
    }

    func appTheme() -> some View {
        modifier(AppThemeModifier())
    }
    
    func appTint() -> some View {
        modifier(AppTintModifier())
    }

    /// System loading indicator used across primary screens.
    func cronicaLoadingOverlay(_ isLoading: Bool) -> some View {
        overlay {
            if isLoading {
                ProgressView()
#if !os(watchOS)
                    .controlSize(.large)
#endif
                    .accessibilityLabel(String(localized: "Loading"))
            }
        }
    }

    /// Standard retry alert for recoverable network errors.
    func cronicaErrorAlert(
        isPresented: Binding<Bool>,
        title: String = String(localized: "Something Went Wrong"),
        message: String = String(localized: "Check your connection and try again."),
        retry: @escaping () -> Void
    ) -> some View {
        alert(title, isPresented: isPresented) {
            Button(String(localized: "Retry"), action: retry)
            Button(String(localized: "Cancel"), role: .cancel) { }
        } message: {
            Text(message)
        }
    }

    /// Adds the system-standard Done button for modal sheets.
    func nativeSheetDismissToolbar(action: @escaping () -> Void) -> some View {
        toolbar {
#if os(macOS)
            ToolbarItem(placement: .cancellationAction) {
                Button("Done", action: action)
            }
#else
            ToolbarItem(placement: .confirmationAction) {
                Button("Done", action: action)
            }
#endif
        }
    }
}

private struct CronicaNavigationTitleModifier: ViewModifier {
    let title: String
    let displayMode: NavigationBarItem.TitleDisplayMode

    func body(content: Content) -> some View {
#if os(iOS)
        content
            .environment(\.textCase, nil)
            .navigationTitle(Text(verbatim: title))
            .navigationBarTitleDisplayMode(displayMode)
#else
        content
            .environment(\.textCase, nil)
            .navigationTitle(title)
#endif
    }
}

struct CronicaListSectionHeader: View {
    let title: String

    var body: some View {
        Text(verbatim: title)
            .textCase(nil)
            .environment(\.textCase, nil)
    }
}

/// List section with sentence-case title for feature screens outside Settings.
struct CronicaListSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    init(_ title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        Section {
            content()
        } header: {
            CronicaListSectionHeader(title: title)
        }
    }
}

struct CronicaFormSectionHeader: View {
    let title: String

    var body: some View {
        Text(verbatim: title)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .environment(\.textCase, .uppercase)
    }
}

/// Footer copy below a settings section — keeps sentence case inside Forms.
struct CronicaFormFooter: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(verbatim: text)
            .textCase(nil)
            .environment(\.textCase, nil)
    }
}

/// Form row label that keeps sentence case inside SwiftUI Forms.
struct CronicaFormText: View {
    let text: String
    var font: Font = .body
    var color: Color?

    init(_ text: String, font: Font = .body, color: Color? = nil) {
        self.text = text
        self.font = font
        self.color = color
    }

    var body: some View {
        Text(verbatim: text)
            .font(font)
            .foregroundStyle(color ?? .primary)
            .textCase(nil)
            .environment(\.textCase, nil)
    }
}

/// Primary and optional subtitle label for Toggle rows in settings forms.
struct CronicaFormToggleLabel: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            CronicaFormText(title)
            if let subtitle {
                CronicaFormText(subtitle, font: .caption, color: .secondary)
            }
        }
    }
}

/// Form section with sentence-case title.
struct CronicaFormSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    init(_ title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        Section {
            content()
        } header: {
            CronicaFormSectionHeader(title: title)
        }
    }
}

/// Form section with sentence-case title and footer.
struct CronicaFormSectionWithFooter<Content: View, Footer: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content
    @ViewBuilder var footer: () -> Footer

    init(
        _ title: String,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder footer: @escaping () -> Footer
    ) {
        self.title = title
        self.content = content
        self.footer = footer
    }

    var body: some View {
        Section {
            content()
        } header: {
            CronicaFormSectionHeader(title: title)
        } footer: {
            footer()
                .environment(\.textCase, nil)
        }
    }
}
