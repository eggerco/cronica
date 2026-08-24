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

    func appTheme() -> some View {
        modifier(AppThemeModifier())
    }
    
    func appTint() -> some View {
        modifier(AppTintModifier())
    }

    /// Standard toolbar icon sizing used across navigation bars.
    func cronicaToolbarIconStyle() -> some View {
        self
            .imageScale(.medium)
            .fontWeight(.semibold)
    }

    /// Standard loading overlay used across primary screens.
    func cronicaLoadingOverlay(_ isLoading: Bool) -> some View {
        overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.06)
                        .ignoresSafeArea()
                    ProgressView()
                        .controlSize(.large)
                        .padding(20)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isLoading)
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
