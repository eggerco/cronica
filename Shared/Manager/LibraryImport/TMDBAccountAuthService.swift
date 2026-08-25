//
//  TMDBAccountAuthService.swift
//  Cronica
//

import Foundation
import AuthenticationServices
import CronicaCore
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit) && os(macOS)
import AppKit
#endif

@MainActor
final class TMDBAccountAuthService: NSObject {
    static let shared = TMDBAccountAuthService()

    static let redirectURI = "cronica://tmdb/callback"

    private var session: ASWebAuthenticationSession?
    private var presentationContext = TMDBAuthPresentationContext()

    private override init() {
        super.init()
    }

    var isConnected: Bool { TMDBSessionStore.hasSession }

    func disconnect() {
        let sessionID = TMDBSessionStore.loadSessionID()
        TMDBSessionStore.delete()
        TMDBPushService.shared.clearQueue()
        TMDBAccountListCache.clear()
        let settings = SettingsStore.shared
        settings.isUserConnectedWithTMDb = false
        settings.tmdbAccountName = ""
        settings.tmdbAccountLastImportDate = nil
        settings.tmdbPushEnabled = false
        settings.markTMDBSyncChecked(Date(timeIntervalSince1970: 0))
        if let sessionID {
            Task {
                try? await TMDBAccountAPIClient.shared.deleteSession(sessionID: sessionID)
            }
        }
    }

#if os(iOS) || os(macOS) || os(visionOS)
    func signIn() async throws {
        guard Key.isConfigured else { throw LibraryImportError.notConfigured }

        let requestToken = try await TMDBAccountAPIClient.shared.createRequestToken()
        var components = URLComponents(string: "https://www.themoviedb.org/authenticate/\(requestToken)")!
        components.queryItems = [URLQueryItem(name: "redirect_to", value: Self.redirectURI)]
        guard let authorizeURL = components.url else { throw LibraryImportError.invalidResponse }

        let callbackURL: URL = try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: authorizeURL,
                callbackURLScheme: "cronica"
            ) { url, error in
                if let error {
                    let nsError = error as NSError
                    if nsError.domain == ASWebAuthenticationSessionErrorDomain,
                       nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        continuation.resume(throwing: LibraryImportError.cancelled)
                    } else {
                        continuation.resume(throwing: error)
                    }
                    return
                }
                guard let url else {
                    continuation.resume(throwing: LibraryImportError.invalidResponse)
                    return
                }
                continuation.resume(returning: url)
            }
            session.presentationContextProvider = presentationContext
            session.prefersEphemeralWebBrowserSession = false
            self.session = session
            if !session.start() {
                continuation.resume(throwing: LibraryImportError.message("Unable to start TMDB sign-in."))
            }
        }

        // TMDB may redirect with approved=true; create session from original request token.
        _ = callbackURL
        let sessionID = try await TMDBAccountAPIClient.shared.createSession(requestToken: requestToken)
        try TMDBSessionStore.saveSessionID(sessionID)

        let account = try await TMDBAccountAPIClient.shared.accountDetails(sessionID: sessionID)
        TMDBSessionStore.saveAccountID(account.id)
        SettingsStore.shared.isUserConnectedWithTMDb = true
        SettingsStore.shared.tmdbAccountName = account.username ?? account.name ?? ""
    }
#endif
}

private final class TMDBAuthPresentationContext: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
#if os(macOS)
        return NSApplication.shared.windows.first { $0.isKeyWindow }
            ?? NSApplication.shared.windows.first
            ?? ASPresentationAnchor()
#else
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        if let window = scenes.flatMap(\.windows).first(where: \.isKeyWindow) {
            return window
        }
        return scenes.flatMap(\.windows).first ?? ASPresentationAnchor()
#endif
    }
}
