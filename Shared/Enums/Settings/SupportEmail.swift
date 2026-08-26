//
//  SupportEmail.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 22/01/23.
//

import SwiftUI

struct SupportEmail {
    let toAddress: String = "support@cronica.watch"
    let subject: String = "Support Email (Cronica App)"
    let messageHeader: String = "Feedback:"
    var body: String {"""
        \(messageHeader)
    """
    }
    
    func send(openURL: OpenURLAction) {
        let urlString = "mailto:\(toAddress)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")"
        guard let url = URL(string: urlString) else { return }
        openURL(url) { _ in
        }
    }
}
