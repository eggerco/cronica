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
    @State private var widgetItem: ItemContent?
    @State private var notificationItem: ItemContent?
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
#endif
                .onOpenURL { url in
                    let urlString = url.absoluteString
                    if urlString.hasPrefix("cronica://") {
                        let urlSubstring = urlString.dropFirst("cronica://".count)
                        Task {
                            await fetchContent(for: String(urlSubstring))
                        }
                    } else {
                        Task {
                            await fetchContent(for: url.absoluteString)
                        }
                    }
                }
                .sheet(item: $selectedItem) { item in
                    NavigationStack {
                        ItemContentDetails(title: item.itemTitle,
                                           id: item.id,
                                           type: item.itemContentMedia, handleToolbar: true)
                        .toolbar {
#if os(iOS)
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Done") { selectedItem = nil }
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
                    .presentationDetents([.large])
                    .frame(minWidth: 800, idealWidth: 800, minHeight: 600, idealHeight: 600, alignment: .center)
#elseif os(iOS)
                    .appTheme()
                    .appTint()
#endif
                }
#if os(macOS)
                .sheet(isPresented: $showFeedbackForm) {
                    FeedbackComposerView(showFeedbackForm: $showFeedbackForm)
                        .frame(width: 400, height: 400, alignment: .center)
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
        .onChange(of: scene) { phase in
            if phase == .background {
                scheduleAppRefresh()
            }
        }
#if os(macOS)
        .commands {
            CommandGroup(after: .sidebar) {
                Picker("appearanceRowStyleTitle", selection: $settings.watchlistStyle) {
                    ForEach(SectionDetailsPreferredStyle.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                Picker("appearanceSectionDetailsTitle", selection: $settings.sectionStyleType) {
                    ForEach(SectionDetailsPreferredStyle.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                Picker("appearanceHorizontalListsTitle", selection: $settings.listsDisplayType) {
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
                Button("aboutTitle") {
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
        if let task {
            scheduleAppRefresh()
            let workItem = Task {
                await BackgroundManager.shared.handleWatchingContentRefresh()
                BackgroundManager.shared.lastWatchingRefresh = Date()
                await BackgroundManager.shared.handleUpcomingContentRefresh()
                BackgroundManager.shared.lastUpcomingRefresh = Date()
                await BackgroundManager.shared.handleAppRefreshMaintenance()
                BackgroundManager.shared.lastMaintenance = Date()
                task.setTaskCompleted(success: true)
            }
            task.expirationHandler = {
                workItem.cancel()
                task.setTaskCompleted(success: false)
            }
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
