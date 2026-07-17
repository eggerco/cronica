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
        registerRefreshBGTask()
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
#if os(iOS)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    Task {
                        guard let id = notificationDelegate.notificationID else { return }
                        if lastNotificationID != id {
                            await fetchContent(for: id)
                        }
                        lastNotificationID = id
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    Task {
                        guard let id = notificationDelegate.notificationID else { return }
                        if lastNotificationID != id {
                            await fetchContent(for: id)
                        }
                        lastNotificationID = id
                    }
                }
#endif
                .onOpenURL { url in
                    Task {
                        await openDeepLink(url)
                    }
                }
                .sheet(item: $selectedItem) { item in
                    NavigationStack {
                        ItemContentDetails(title: item.itemTitle,
                                           id: item.id,
                                           type: item.itemContentMedia, handleToolbar: true)
                        .toolbar {
#if os(iOS)
                            ToolbarItem(placement: .topBarLeading) {
                                RoundedCloseButton {
                                    selectedItem = nil
                                }
                            }
#else
                            Button("Done") { selectedItem = nil }
#endif
                        }
                        .navigationDestination(for: ItemContent.self) { item in
                            ItemContentDetails(title: item.itemTitle,
                                               id: item.id,
                                               type: item.itemContentMedia)
                        }
                        .navigationDestination(for: Person.self) { person in
                            PersonDetailsView(name: person.name, id: person.id)
                        }
                        .navigationDestination(for: [String:[ItemContent]].self) { item in
                            let keys = item.map { (key, _) in key }
                            let value = item.map { (_, value) in value }
                            ItemContentSectionDetails(title: keys[0], items: value[0])
                        }
                        .navigationDestination(for: [Person].self) { items in
                            DetailedPeopleList(items: items)
                        }
                        .navigationDestination(for: ProductionCompany.self) { item in
                            CompanyDetails(company: item)
                        }
                        .navigationDestination(for: [ProductionCompany].self) { item in
                            CompaniesListView(companies: item)
                        }
                    }
                    .onDisappear { selectedItem = nil }
#if os(macOS)
                    .frame(minWidth: 800, idealWidth: 800, minHeight: 600, idealHeight: 600, alignment: .center)
#else
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(12)
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
    
    private func openDeepLink(_ url: URL) async {
        if let contentID = Self.contentID(from: url) {
            await fetchContent(for: contentID)
        }
    }

    /// Accepts `cronica://123@0`, bare `123@0`, or `https://www.oncronica.com/details?id=123@0`.
    static func contentID(from url: URL) -> String? {
        let absolute = url.absoluteString
        if absolute.hasPrefix("cronica://") {
            let id = String(absolute.dropFirst("cronica://".count))
            return id.isEmpty ? nil : id.removingPercentEncoding ?? id
        }
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let id = components.queryItems?.first(where: { $0.name == "id" })?.value,
           !id.isEmpty {
            return id
        }
        if absolute.contains("@"), !absolute.contains("://") {
            return absolute
        }
        return nil
    }

    private func fetchContent(for id: String) async {
        if selectedItem != nil { selectedItem = nil }
        let type = id.last ?? "0"
        var media: MediaType = .movie
        if type == "1" {
            media = .tvShow
        }
        let contentID = String(id.dropLast(2))
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
        let refreshTask = Task {
            await BackgroundManager.shared.handleWatchingContentRefresh()
            await BackgroundManager.shared.handleUpcomingContentRefresh()
            await BackgroundManager.shared.handleAppRefreshMaintenance()
        }
        task.expirationHandler = {
            refreshTask.cancel()
        }
        Task {
            await refreshTask.value
            task.setTaskCompleted(success: !Task.isCancelled)
        }
    }
#elseif os(macOS)
    private func handleAppRefresh() {
        Task {
            await BackgroundManager.shared.handleWatchingContentRefresh()
            await BackgroundManager.shared.handleUpcomingContentRefresh()
            await BackgroundManager.shared.handleAppRefreshMaintenance()
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
