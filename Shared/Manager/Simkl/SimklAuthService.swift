//
//  SimklAuthService.swift
//  Cronica
//

import Foundation
import AuthenticationServices
import CryptoKit
import CronicaCore
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit) && os(macOS)
import AppKit
#endif

@MainActor
final class SimklAuthService: NSObject {
    static let shared = SimklAuthService()

    static let redirectURI = "cronica://simkl/callback"

    private var session: ASWebAuthenticationSession?
    private var presentationContext = SimklAuthPresentationContext()

    private override init() {
        super.init()
    }

    var isConnected: Bool { SimklTokenStore.hasToken }

    func disconnect() {
        SimklTokenStore.delete()
        SimklKnownItemsStore.clear()
        SimklPushService.shared.clearQueue()
        let settings = SettingsStore.shared
        settings.isSimklConnected = false
        settings.simklLastImportDate = nil
        settings.simklActivitiesAll = ""
        settings.simklRemovedMovies = ""
        settings.simklRemovedShows = ""
        settings.simklRemovedAnime = ""
        settings.simklTVWatching = ""
        settings.simklTVHold = ""
        settings.simklAnimeWatching = ""
        settings.simklAnimeHold = ""
        settings.markSimklActivitiesChecked(Date(timeIntervalSince1970: 0))
        settings.simklPushEnabled = false
    }

#if os(iOS) || os(macOS) || os(visionOS)
    func signInWithPKCE() async throws {
        guard Key.isSimklConfigured else { throw SimklError.notConfigured }

        let verifier = Self.makeCodeVerifier()
        let challenge = Self.makeCodeChallenge(from: verifier)
        let authorizeURL = try Self.authorizeURL(codeChallenge: challenge)

        let callbackURL: URL = try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: authorizeURL,
                callbackURLScheme: "cronica"
            ) { url, error in
                if let error {
                    let nsError = error as NSError
                    if nsError.domain == ASWebAuthenticationSessionErrorDomain,
                       nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        continuation.resume(throwing: SimklError.cancelled)
                    } else {
                        continuation.resume(throwing: error)
                    }
                    return
                }
                guard let url else {
                    continuation.resume(throwing: SimklError.invalidResponse)
                    return
                }
                continuation.resume(returning: url)
            }
            session.presentationContextProvider = presentationContext
            session.prefersEphemeralWebBrowserSession = false
            self.session = session
            if !session.start() {
                continuation.resume(throwing: SimklError.message("Unable to start SIMKL sign-in."))
            }
        }

        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            throw SimklError.invalidResponse
        }

        let token = try await SimklAPIClient.shared.exchangeCode(
            code,
            codeVerifier: verifier,
            redirectURI: Self.redirectURI
        )
        try SimklTokenStore.save(token.accessToken)
        SettingsStore.shared.isSimklConnected = true
    }
#endif

#if os(tvOS)
    struct PinSession {
        let userCode: String
        let verificationURL: URL
        let expiresIn: Int
        let interval: Int
    }

    func beginPINSignIn() async throws -> PinSession {
        guard Key.isSimklConfigured else { throw SimklError.notConfigured }
        let response = try await SimklAPIClient.shared.requestPin()
        let url = URL(string: response.verificationUrl ?? "https://simkl.com/pin")
            ?? URL(string: "https://simkl.com/pin")!
        return PinSession(
            userCode: response.userCode,
            verificationURL: url,
            expiresIn: response.expiresIn ?? 900,
            interval: max(response.interval ?? 5, 5)
        )
    }

    func pollPIN(userCode: String, expiresIn: Int, interval: Int) async throws {
        let deadline = Date().addingTimeInterval(TimeInterval(expiresIn))
        while Date() < deadline {
            try Task.checkCancellation()
            let poll = try await SimklAPIClient.shared.pollPin(userCode: userCode)
            if let token = poll.accessToken, !token.isEmpty {
                try SimklTokenStore.save(token)
                SettingsStore.shared.isSimklConnected = true
                return
            }
            try await Task.sleep(nanoseconds: UInt64(interval) * 1_000_000_000)
        }
        throw SimklError.message("PIN expired. Try connecting again.")
    }
#endif

    // MARK: - PKCE helpers

    private static func makeCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64URLEncodedString()
    }

    private static func makeCodeChallenge(from verifier: String) -> String {
        let digest = SHA256.hash(data: Data(verifier.utf8))
        return Data(digest).base64URLEncodedString()
    }

    private static func authorizeURL(codeChallenge: String) throws -> URL {
        let clientID = Key.simklClientID
        guard !clientID.isEmpty else { throw SimklError.notConfigured }
        var components = URLComponents(string: "https://simkl.com/oauth/authorize")!
        components.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]
        guard let url = components.url else { throw SimklError.invalidResponse }
        return url
    }
}

private final class SimklAuthPresentationContext: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
#if os(macOS)
        return NSApplication.shared.windows.first ?? ASPresentationAnchor()
#else
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        if let window = scenes.flatMap(\.windows).first(where: \.isKeyWindow) {
            return window
        }
        return scenes.flatMap(\.windows).first ?? ASPresentationAnchor()
#endif
    }
}

private extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
