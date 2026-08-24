//
//  NotificationListView.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 25/09/22.
//

import SwiftUI

#if !os(tvOS)
struct NotificationListView: View {
    @Binding var showNotification: Bool
    @State private var hasLoaded = false
    @State private var items = [ItemContent]()
    @State private var deliveredItems = [ItemContent]()
    @State private var showPopup = false
    @State private var popupType: ActionPopupItems?
    var body: some View {
        Form {
            if hasLoaded {
                List {
                    deliveredItemsView
                    upcomingItemsView
                }
            } else {
                EmptyView()
            }
        }
        .cronicaLoadingOverlay(!hasLoaded)
        .actionPopup(isShowing: $showPopup, for: popupType)
        .navigationTitle("Notifications")
        .cronicaSettingsForm()
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
        .toolbar {
#if os(iOS)
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    NavigationLink(value: ReleaseCalendarRoute.watchlist) {
                        Label("Release Calendar", systemImage: "calendar")
                    }
                    configButton
                }
            }
#elseif os(macOS)
            ToolbarItem(placement: .automatic) {
                NavigationLink(value: ReleaseCalendarRoute.watchlist) {
                    Label("Release Calendar", systemImage: "calendar")
                }
            }
            ToolbarItem(placement: .automatic) {
                configButton
            }
#endif
        }
        .task { await load() }
        .scrollBounceBehavior(.basedOnSize)
        .navigationDestination(for: ReleaseCalendarRoute.self) { _ in
            ReleaseCalendarView()
        }
        .cronicaStandardNavigationDestinations()
    }
    
    private var configButton: some View {
        NavigationLink(destination: NotificationsSettingsView()) {
            Label("Settings", systemImage: "gearshape")
        }
    }
    
    @ViewBuilder
    private var deliveredItemsView: some View {
        if !deliveredItems.isEmpty {
            CronicaFormSection("Recent Notifications") {
                ForEach(deliveredItems.sorted(by: { $0.itemTitle < $1.itemTitle })) { item in
                    ItemContentRowView(item: item, showPopup: $showPopup, popupType: $popupType, showNotificationDate: true)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                removeDelivered(id: item.itemContentID, for: item.id)
                            } label: {
                                Label("Remove Notification", systemImage: "bell.slash.circle.fill")
                            }
                        }
                }
            }
        }
    }
    
    @ViewBuilder
    private var upcomingItemsView: some View {
        if items.isEmpty, deliveredItems.isEmpty {
            CenterHorizontalView {
                Text("No Notifications")
                    .padding()
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
        } else {
            CronicaFormSection("Upcoming Notifications") {
                ForEach(items) { item in
                    ItemContentRowView(item: item, showPopup: $showPopup, popupType: $popupType, showNotificationDate: true)
                        .onAppear {
                            let isStillSaved = PersistenceController.shared.isItemSaved(id: item.itemContentID)
                            if !isStillSaved {
                                NotificationManager.shared.removeNotification(identifier: item.itemContentID)
                            }
                        }
                }
            }
        }
    }
    
    private func dismiss() { showNotification.toggle() }
    
    private func load() async {
        if hasLoaded { return }
        let upcomingContent = await NotificationManager.shared.fetchUpcomingNotifications() ?? []
        if !upcomingContent.isEmpty {
            let orderedContent = upcomingContent.sorted(by: { $0.itemNotificationSortDate ?? Date.distantPast < $1.itemNotificationSortDate ?? Date.distantPast})
            items = orderedContent
        }
        deliveredItems = await NotificationManager.shared.fetchDeliveredNotifications()
        withAnimation { hasLoaded = true }
        //await MainActor.run { withAnimation { self.hasLoaded = true } }
    }
    
    private func removeDelivered(id: String, for content: Int) {
        NotificationManager.shared.removeDeliveredNotification(identifier: id)
        withAnimation { items.removeAll(where: { $0.id == content }) }
    }
}

#Preview {
    NotificationListView(showNotification: .constant(true))
}
#endif
