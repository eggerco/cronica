//
//  NetworkError.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 09/05/22.
//

import Foundation
import SwiftUI

public enum NetworkError: Error, CustomNSError {
    case invalidResponse, invalidRequest, invalidEndpoint, decodingError
    case invalidApi, internalError, maintenanceApi, contentRemoved
    public var localizedName: String {
        switch self {
        case .invalidResponse:
            return String(localized: "Invalid Response", bundle: .main)
        case .invalidRequest:
            return String(localized: "Invalid Request", bundle: .main)
        case .invalidEndpoint:
            return String(localized: "Invalid Endpoint", bundle: .main)
        case .decodingError:
            return String(localized: "Error reading this title", bundle: .main)
        case .invalidApi:
            return String(localized: "Invalid API key: You must be granted a valid key.", bundle: .main)
        case .internalError:
            return String(localized: "Internal error: Something went wrong, contact TMDB.", bundle: .main)
        case .maintenanceApi:
            return String(localized: "The API is undergoing maintenance. Try again later.", bundle: .main)
        case .contentRemoved:
            return String(localized: "This content has been removed from TMDB, you can delete it.", bundle: .main)
        }
    }
}
