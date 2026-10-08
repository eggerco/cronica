//
//  CloudKitSyncStatusStore.swift
//  Cronica
//

import CloudKit
import Combine
import CoreData
import Foundation

/// Observes CloudKit account + mirroring events for Privacy & Data status.
@MainActor
final class CloudKitSyncStatusStore: ObservableObject {
    static let shared = CloudKitSyncStatusStore()

    @Published private(set) var statusTitle: String = String(localized: "Checking…")
    @Published private(set) var statusDetail: String = ""
    @Published private(set) var lastSuccessfulSync: Date?
    @Published private(set) var isAccountAvailable = false
    @Published private(set) var isMirroringEnabled = false

    private let lastSyncKey = "cloudKit.lastSuccessfulSync"
    private var eventObserver: NSObjectProtocol?
    private var accountObserver: NSObjectProtocol?
    private var didStart = false

    private init() {
        lastSuccessfulSync = UserDefaults.standard.object(forKey: lastSyncKey) as? Date
    }

    func startIfNeeded() {
        // Avoid CKContainer calls under XCTest (unsigned CI hosts lack iCloud entitlements).
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }

        guard !didStart else {
            Task { await refreshAccountStatus() }
            return
        }
        didStart = true

        eventObserver = NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                    as? NSPersistentCloudKitContainer.Event
            else { return }
            Task { @MainActor in
                self?.handle(event)
            }
        }

        accountObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name.CKAccountChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshAccountStatus()
            }
        }

        Task { await refreshAccountStatus() }
    }

    func refreshAccountStatus() async {
#if CRONICA_SHARE_EXTENSION || CRONICA_WIDGET_EXTENSION
        isMirroringEnabled = false
        isAccountAvailable = false
        statusTitle = String(localized: "Unavailable")
        statusDetail = String(localized: "iCloud sync runs in the main Cronica app.")
        return
#else
        isMirroringEnabled = PersistenceController.shared.container
            .persistentStoreDescriptions
            .contains { $0.cloudKitContainerOptions != nil }

        let container = CKContainer(identifier: PersistenceController.cloudKitContainerIdentifier)
        let status: CKAccountStatus
        do {
            status = try await container.accountStatus()
        } catch {
            isAccountAvailable = false
            statusTitle = String(localized: "Couldn't Check iCloud")
            statusDetail = error.localizedDescription
            return
        }

        switch status {
        case .available:
            isAccountAvailable = true
            statusTitle = String(localized: "iCloud Sync On")
            if let lastSuccessfulSync {
                statusDetail = String(
                    format: String(localized: "Last activity %@"),
                    lastSuccessfulSync.formatted(date: .abbreviated, time: .shortened)
                )
            } else {
                statusDetail = String(localized: "Waiting for the first sync with your other Apple devices. Keep Cronica open on Wi‑Fi for a few minutes.")
            }
        case .noAccount:
            isAccountAvailable = false
            statusTitle = String(localized: "Signed Out of iCloud")
            statusDetail = String(localized: "Sign in with the same Apple ID on each device, then open Cronica again.")
        case .restricted:
            isAccountAvailable = false
            statusTitle = String(localized: "iCloud Restricted")
            statusDetail = String(localized: "iCloud is restricted on this device, so Cronica can't sync.")
        case .couldNotDetermine:
            isAccountAvailable = FileManager.default.ubiquityIdentityToken != nil
            statusTitle = String(localized: "Checking iCloud…")
            statusDetail = String(localized: "Apple hasn't confirmed the iCloud account yet. Try again in a moment.")
        case .temporarilyUnavailable:
            isAccountAvailable = false
            statusTitle = String(localized: "iCloud Temporarily Unavailable")
            statusDetail = String(localized: "Try again when your network or Apple Account is available.")
        @unknown default:
            isAccountAvailable = false
            statusTitle = String(localized: "iCloud Status Unknown")
            statusDetail = String(localized: "Open Settings → Apple Account → iCloud and make sure Cronica is enabled.")
        }

        if isAccountAvailable && !isMirroringEnabled {
            statusTitle = String(localized: "iCloud Sync Unavailable")
            statusDetail = String(localized: "Restart Cronica to attach iCloud sync on this device.")
        }
#endif
    }

    private func handle(_ event: NSPersistentCloudKitContainer.Event) {
        switch event.type {
        case .setup:
            break
        case .import, .export:
            if event.endDate != nil, event.error == nil {
                let date = event.endDate ?? Date()
                lastSuccessfulSync = date
                UserDefaults.standard.set(date, forKey: lastSyncKey)
                Task { await refreshAccountStatus() }
            } else if let error = event.error {
                AppLogger.persistence.error(
                    "CloudKit \(String(describing: event.type)) failed: \(error.localizedDescription)"
                )
                statusDetail = error.localizedDescription
            }
        @unknown default:
            break
        }
    }
}
