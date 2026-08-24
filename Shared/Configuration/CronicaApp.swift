//
//  CronicaApp.swift
//  Shared
//
//  Created by Alexandre Madeira on 14/01/22.
//
import SwiftUI
import BackgroundTasks
#if os(iOS)
import NotificationCenter
#endif

@main
struct CronicaApp: App {
    var persistence = PersistenceController.shared
    private let backgroundIdentifier = "dev.alexandremadeira.cronica.refreshContent"
    @Environment(\.scenePhase) private var scene
#if !os(watchOS) && !os(tvOS)
    private static var hasSyncedCalendarThisLaunch = false
#endif
    @State private var selectedItem: ItemContent?
    @State private var showFeedbackForm = false
    @State private var showAbout = false
    @State private var showNewListView = false
    @ObservedObject private var settings = SettingsStore.shared
    @AppStorage("showMenuBarApp") var showMenuBar = true
#if os(iOS)
    @ObservedObject private var notificationDelegate = NotificationDelegate()
    @State private var lastNotificationID = String()
#endif
    init() {
        CronicaTelemetry.shared.setup()
        SentryManager.setup()
        registerRefreshBGTask()
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-ui-testing") {
            UserDefaults.standard.set(false, forKey: "showOnboarding")
        }
#endif
#if os(iOS)
        UNUserNotificationCenter.current().delegate = notificationDelegate
#endif
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
#if os(macOS)
                .frame(minWidth: 1000, minHeight: 600)
#elseif os(visionOS)
                .frame(minWidth: 800)
#endif
                .environment(\.managedObjectContext, persistence.container.viewContext)
                .onOpenURL { url in
                    guard let contentID = Self.contentID(from: url) else { return }
                    Task {
                        await fetchContent(for: contentID)
                    }
                }
                .sheet(item: $selectedItem) { item in
                    NavigationStack {
                        ItemContentDetails(title: item.itemTitle,
                                           id: item.id,
                                           type: item.itemContentMedia, handleToolbar: true)
                        .nativeSheetDismissToolbar { selectedItem = nil }
                        .cronicaStandardNavigationDestinations(itemContentHandleToolbar: true)
                    }
                    .onDisappear { selectedItem = nil }
#if os(macOS)
                    .frame(minWidth: 800, idealWidth: 800, minHeight: 600, idealHeight: 600, alignment: .center)
#else
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .appTheme()
                    .appTint()
#endif
                }
#if os(macOS)
                .sheet(isPresented: $showFeedbackForm) {
                    NavigationStack {
                        FeedbackComposerView()
                    }
                    .frame(width: 400, height: 400, alignment: .center)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") {
                                showFeedbackForm = false
                            }
                        }
                    }
                }
                .sheet(isPresented: $showAbout) {
                    NavigationStack {
                        AboutSettings()
                            .navigationDestination(for: SettingsScreens.self) { _ in
                                DeveloperView()
                            }
                    }
                    .frame(width: 400, height: 400, alignment: .center)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") {
                                showAbout = false
                            }
                        }
                    }
                }
#endif
        }
#if os(visionOS)
        .windowResizability(.contentMinSize)
#endif
        .onChange(of: scene) { _, phase in
            if phase == .background {
                scheduleAppRefresh()
            }
#if !os(watchOS) && !os(tvOS)
            if phase == .active, !Self.hasSyncedCalendarThisLaunch, settings.allowCalendarSync {
                Self.hasSyncedCalendarThisLaunch = true
                Task { await CalendarManager.shared.syncAll() }
            }
#endif
#if os(iOS)
            if phase == .active {
                Task {
                    guard let id = notificationDelegate.notificationID else { return }
                    if lastNotificationID != id {
                        await fetchContent(for: id)
                    }
                    lastNotificationID = id
                }
            }
#endif
        }
#if os(macOS)
        .commands {
            CommandGroup(after: .sidebar) {
                Picker("Watchlist Style", selection: $settings.watchlistStyle) {
                    ForEach(SectionDetailsPreferredStyle.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                Picker("Section Details Style", selection: $settings.sectionStyleType) {
                    ForEach(SectionDetailsPreferredStyle.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                Picker("Horizontal List Style", selection: $settings.listsDisplayType) {
                    ForEach(ItemContentListPreferredDisplayType.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
            }
            
            CommandGroup(replacing: .help) {
                Button("Send Feedback") {
                    showFeedbackForm = true
                }
            }
            
            CommandGroup(replacing: .appInfo) {
                Button("About") {
                    showAbout.toggle()
                }
            }
        }
#endif
        
#if os(macOS)
        Settings {
            SettingsView()
        }
        
        MenuBarExtra("Up Next (Cronica)", systemImage: "popcorn", isInserted: $showMenuBar) {
            VStack {
                UpNextMenuBar()
                    .environment(\.managedObjectContext, persistence.container.viewContext)
            }
            .frame(minWidth: 360, minHeight: 300, maxHeight: 600)
        }
        .menuBarExtraStyle(.window)
#endif
    }
    
    static func contentID(from url: URL) -> String? {
        if url.scheme?.lowercased() == "cronica" {
            let raw = url.absoluteString.dropFirst("cronica://".count)
            let id = String(raw.split(separator: "?").first ?? Substring(raw))
            return id.isEmpty ? nil : id
        }

        guard url.host()?.lowercased() == "cronica.eggerco.com" else { return nil }
        let path = url.path()
        guard path == "/details" || path == "details" else { return nil }

        return URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "id" })?
            .value
    }

    private func fetchContent(for id: String) async {
        if selectedItem != nil { selectedItem = nil }
        let type = id.last ?? "0"
        var media: MediaType = .movie
        if type == "1" {
            media = .tvShow
        }
        let contentID = id.dropLast(2)
        guard let contentIDNumber = Int(contentID) else { return }
        let item = try? await NetworkService.shared.fetchItem(id: contentIDNumber, type: media)
        guard let item else { return }
        self.selectedItem = item
    }
    
    private func registerRefreshBGTask() {
#if os(iOS)
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundIdentifier, using: nil) { task in
            self.handleAppRefresh(task: task as? BGAppRefreshTask ?? nil)
        }
#elseif os(macOS)
        _ = Timer.scheduledTimer(withTimeInterval: 10 * 3600, repeats: true) { _ in
            self.handleAppRefresh()
        }
#endif
    }
    
    private func scheduleAppRefresh() {
#if os(iOS)
        let request = BGAppRefreshTaskRequest(identifier: backgroundIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 180 * 60) // Fetch no earlier than 3 hours from now
        try? BGTaskScheduler.shared.submit(request)
#endif
    }
    
#if os(iOS)
    // Fetch the latest updates from api.
    private func handleAppRefresh(task: BGAppRefreshTask?) {
        guard let task else { return }
        scheduleAppRefresh()

        let workItem = Task {
            await BackgroundManager.shared.handleWatchingContentRefresh()
            BackgroundManager.shared.lastWatchingRefresh = Date()
            await BackgroundManager.shared.handleUpcomingContentRefresh()
            BackgroundManager.shared.lastUpcomingRefresh = Date()
            await BackgroundManager.shared.handleAppRefreshMaintenance()
            BackgroundManager.shared.lastMaintenance = Date()
            guard !Task.isCancelled else { return }
            task.setTaskCompleted(success: true)
        }
        task.expirationHandler = {
            workItem.cancel()
            task.setTaskCompleted(success: false)
        }
    }
#elseif os(macOS)
    private func handleAppRefresh() {
        Task {
            await BackgroundManager.shared.handleWatchingContentRefresh()
            BackgroundManager.shared.lastWatchingRefresh = Date()
            await BackgroundManager.shared.handleUpcomingContentRefresh()
            BackgroundManager.shared.lastUpcomingRefresh = Date()
            await BackgroundManager.shared.handleAppRefreshMaintenance()
            BackgroundManager.shared.lastMaintenance = Date()
        }
    }
#endif
}

#if os(iOS)
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, ObservableObject {
    
    var notificationID: String?
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        // Get the ID of the notification from its userInfo dictionary
        notificationID = response.notification.request.content.userInfo["contentID"] as? String
        
        completionHandler()
    }
}
#endif
