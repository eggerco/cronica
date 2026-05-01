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
import GoogleMobileAds
import UIKit

enum PreviewVideoRuntime {
    static let scenarioArgument = "--preview-video-scenario"
    static let disableMonetizationArgument = "--preview-video-disable-monetization"

    static func scenarioID(arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: scenarioArgument) else { return nil }
        let nextIndex = arguments.index(after: index)
        guard nextIndex < arguments.endIndex else { return nil }
        let scenarioID = arguments[nextIndex].trimmingCharacters(in: .whitespacesAndNewlines)
        return scenarioID.isEmpty ? nil : scenarioID
    }

    static func shouldDisableMonetization(arguments: [String]) -> Bool {
        arguments.contains(disableMonetizationArgument) || scenarioID(arguments: arguments) != nil
    }

    static func shouldDisableMonetization(processInfo: ProcessInfo = .processInfo) -> Bool {
        shouldDisableMonetization(arguments: processInfo.arguments)
    }
}

protocol MobileAdsStarting {
    func start() async
}

protocol AdConsentGathering {
    func gatherConsentIfPossible(from viewController: UIViewController?) async
}

protocol AdPreloading {
    func preloadAds() async
}

protocol AdPreloadCoordinating {
    func loadAd()
    func loadAppOpenAd()
}

extension AdCoordinator: AdPreloadCoordinating {}

protocol AdForegroundPresenting {
    func ensureInterstitialLoaded()
    func presentAppOpenAd()
}

extension AdCoordinator: AdForegroundPresenting {}

struct MobileAdsStarter: MobileAdsStarting {
    @MainActor
    func start() async {
        await MobileAds.shared.start()
    }
}

struct AdConsentGatherer: AdConsentGathering {
    @MainActor
    func gatherConsentIfPossible(from viewController: UIViewController?) async {
        guard let viewController else { return }
        await AdConsentManager.gatherConsent(from: viewController)
    }
}

struct SharedAdPreloader: AdPreloading {
    let adCoordinator: AdPreloadCoordinating

    init(adCoordinator: AdPreloadCoordinating = AdCoordinator.shared) {
        self.adCoordinator = adCoordinator
    }

    @MainActor
    func preloadAds() async {
        adCoordinator.loadAd()
        adCoordinator.loadAppOpenAd()
    }
}

struct AdStartupCoordinator {
    let mobileAdsStarter: MobileAdsStarting
    let consentGatherer: AdConsentGathering
    let adPreloader: AdPreloading

    init(
        mobileAdsStarter: MobileAdsStarting = MobileAdsStarter(),
        consentGatherer: AdConsentGathering = AdConsentGatherer(),
        adPreloader: AdPreloading = SharedAdPreloader()
    ) {
        self.mobileAdsStarter = mobileAdsStarter
        self.consentGatherer = consentGatherer
        self.adPreloader = adPreloader
    }

    func startAdsIfNeeded(
        monetizationDisabled: Bool,
        rootViewController: UIViewController?
    ) async {
        guard !monetizationDisabled else { return }

        await mobileAdsStarter.start()
        await adPreloader.preloadAds()
        await consentGatherer.gatherConsentIfPossible(from: rootViewController)
    }
}

struct AdForegroundPresentationCoordinator {
    let adPresenter: AdForegroundPresenting

    init(adPresenter: AdForegroundPresenting = AdCoordinator.shared) {
        self.adPresenter = adPresenter
    }

    func presentForegroundAdsIfNeeded(monetizationDisabled: Bool) {
        guard !monetizationDisabled else { return }
        adPresenter.ensureInterstitialLoaded()
        adPresenter.presentAppOpenAd()
    }
}

final class CronicaAdAppDelegate: NSObject, UIApplicationDelegate {
    private let adStartupCoordinator = AdStartupCoordinator()
    private let adForegroundCoordinator = AdForegroundPresentationCoordinator()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        Task { @MainActor in
            await adStartupCoordinator.startAdsIfNeeded(
                monetizationDisabled: PreviewVideoRuntime.shouldDisableMonetization(),
                rootViewController: launchRootViewController()
            )
        }
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        adForegroundCoordinator.presentForegroundAdsIfNeeded(
            monetizationDisabled: PreviewVideoRuntime.shouldDisableMonetization()
        )
    }

    private func launchRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return nil
        }
        return windowScene.windows.first(where: \.isKeyWindow)?.rootViewController
            ?? windowScene.windows.first?.rootViewController
    }
}
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
    @UIApplicationDelegateAdaptor(CronicaAdAppDelegate.self) private var adAppDelegate
    private let adForegroundCoordinator = AdForegroundPresentationCoordinator()
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
#if os(iOS)
            if phase == .active {
                adForegroundCoordinator.presentForegroundAdsIfNeeded(
                    monetizationDisabled: PreviewVideoRuntime.shouldDisableMonetization()
                )
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
            let queue = OperationQueue()
            queue.maxConcurrentOperationCount = 1
            task.expirationHandler = {
                // After all operations are cancelled, the completion block below is called to set the task to complete.
                queue.cancelAllOperations()
            }
            queue.addOperation {
                Task {
                    await BackgroundManager.shared.handleWatchingContentRefresh()
                    BackgroundManager.shared.lastWatchingRefresh = Date()
                    await BackgroundManager.shared.handleUpcomingContentRefresh()
                    BackgroundManager.shared.lastUpcomingRefresh = Date()
                    await BackgroundManager.shared.handleAppRefreshMaintenance()
                    BackgroundManager.shared.lastMaintenance = Date()
                }
            }
            task.setTaskCompleted(success: true)
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
