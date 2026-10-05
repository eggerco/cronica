//
//  TMDBConnectionFailure.swift
//  Cronica
//

import Foundation

/// Transport or geo-block failures talking to The Movie Database.
///
/// Cronica cannot distinguish TMDB’s country block from an ISP/DNS block;
/// both look like a failed host lookup or TCP connect (often to `127.0.0.1`).
public enum TMDBConnectionFailure: Equatable, Sendable, LocalizedError {
    /// Device has no usable network.
    case offline
    /// DNS, TCP, TLS, or timeout — typical of TMDB geo-DNS and ISP blocks.
    case unreachable
    /// HTTP 403, including CloudFront country blocks.
    case accessDenied

    public var errorDescription: String? { message }

    public var asNetworkError: NetworkError {
        switch self {
        case .offline: return .offline
        case .unreachable: return .unreachable
        case .accessDenied: return .accessDenied
        }
    }

    public var title: String {
        switch self {
        case .offline:
            return String(localized: "Couldn't Load", bundle: .main)
        case .unreachable, .accessDenied:
            return String(localized: "Can't Reach TMDB", bundle: .main)
        }
    }

    public var message: String {
        switch self {
        case .offline:
            return String(localized: "Check your connection and try again.", bundle: .main)
        case .unreachable:
            return String(
                localized: "Cronica couldn't connect to The Movie Database. TMDB may be blocked on your network or in your region.",
                bundle: .main
            )
        case .accessDenied:
            return String(
                localized: "TMDB blocked this request. The catalog service may be unavailable in your region.",
                bundle: .main
            )
        }
    }

    public var showsRegionHelp: Bool {
        switch self {
        case .offline: return false
        case .unreachable, .accessDenied: return true
        }
    }

    public static func classify(_ error: Error) -> TMDBConnectionFailure? {
        if let failure = error as? TMDBConnectionFailure {
            return failure
        }
        if let networkError = error as? NetworkError {
            return classify(networkError)
        }
        if let urlError = error as? URLError {
            return classify(urlError)
        }
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return classify(URLError(URLError.Code(rawValue: nsError.code)))
        }
        if nsError.domain == NSPOSIXErrorDomain {
            switch nsError.code {
            case Int(ECONNREFUSED), Int(ENETUNREACH), Int(EHOSTUNREACH), Int(ETIMEDOUT):
                return .unreachable
            default:
                break
            }
        }
        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? Error {
            return classify(underlying)
        }
        return nil
    }

    public static func classify(_ error: NetworkError) -> TMDBConnectionFailure? {
        switch error {
        case .offline: return .offline
        case .unreachable: return .unreachable
        case .accessDenied: return .accessDenied
        default: return nil
        }
    }

    public static func classify(_ error: URLError) -> TMDBConnectionFailure? {
        switch error.code {
        case .notConnectedToInternet, .dataNotAllowed, .internationalRoamingOff:
            return .offline
        case .cannotFindHost,
             .cannotConnectToHost,
             .dnsLookupFailed,
             .timedOut,
             .networkConnectionLost,
             .secureConnectionFailed,
             .serverCertificateUntrusted,
             .serverCertificateHasUnknownRoot,
             .serverCertificateHasBadDate,
             .serverCertificateNotYetValid,
             .clientCertificateRejected,
             .clientCertificateRequired,
             .appTransportSecurityRequiresSecureConnection,
             .cannotLoadFromNetwork,
             .resourceUnavailable:
            return .unreachable
        default:
            return nil
        }
    }

    /// Prefer a classified TMDB message; otherwise keep the original localized description.
    public static func userFacingMessage(for error: Error) -> String {
        if let classified = classify(error) {
            return classified.message
        }
        if let localized = error as? LocalizedError, let description = localized.errorDescription, !description.isEmpty {
            return description
        }
        return error.localizedDescription
    }
}
