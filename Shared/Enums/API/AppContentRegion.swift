//
//  WatchProviderOption.swift
//  Cronica (iOS)
//
//  Created by Alexandre Madeira on 14/01/23.
//  swiftlint:disable identifier_name

import Foundation

enum AppContentRegion: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case ae, ar, at, au, be, bg, br,
         ca, ch, cz, de, dk, ee, es, fi,
         fr, gb, hk, hr, hu, id, ie, il, india, it,
         jp, kr, lt, mx, nl, no, nz, ph, pl,
         pt, rs, se, sk, tr, us, za
    var localizableTitle: String {
        switch self {
        case .br: String(localized: "Brazil")
        case .us: String(localized: "United States")
        case .ae: String(localized: "United Arab Emirates")
        case .ar: String(localized: "Argentina")
        case .at: String(localized: "Austria")
        case .au: String(localized: "Australia")
        case .be: String(localized: "Belgium")
        case .bg: String(localized: "Bulgaria")
        case .ca: String(localized: "Canada")
        case .ch: String(localized: "Switzerland")
        case .cz: String(localized: "Czech Republic")
        case .de: String(localized: "Germany")
        case .dk: String(localized: "Denmark")
        case .ee: String(localized: "Estonia")
        case .es: String(localized: "Spain")
        case .fi: String(localized: "Finland")
        case .fr: String(localized: "France")
        case .gb: String(localized: "United Kingdom")
        case .hk: String(localized: "Hong Kong")
        case .hr: String(localized: "Croatia")
        case .hu: String(localized: "Hungary")
        case .id: String(localized: "Indonesia")
        case .ie: String(localized: "Ireland")
        case .india: String(localized: "India")
        case .it: String(localized: "Italy")
        case .jp: String(localized: "Japan")
        case .kr: String(localized: "South Korea")
        case .lt: String(localized: "Lithuania")
        case .mx: String(localized: "Mexico")
        case .nl: String(localized: "Netherlands")
        case .no: String(localized: "Norway")
        case .nz: String(localized: "New Zealand")
        case .ph: String(localized: "Philippines")
        case .pl: String(localized: "Poland")
        case .pt: String(localized: "Portugal")
        case .rs: String(localized: "Serbia")
        case .se: String(localized: "Sweden")
        case .sk: String(localized: "Slovakia")
        case .tr: String(localized: "Turkey")
        case .za: String(localized: "South Africa")
        case .il: String(localized: "Israel")
        }
    }

    var bcp47Identifier: String {
        switch self {
        case .ae: "ar-AE"
        case .ar: "es-AR"
        case .at: "de-AT"
        case .au: "en-AU"
        case .be: "nl-BE"
        case .bg: "bg-BG"
        case .br: "pt-BR"
        case .ca: "en-CA"
        case .ch: "de-CH"
        case .cz: "cs-CZ"
        case .de: "de-DE"
        case .dk: "da-DK"
        case .ee: "et-EE"
        case .es: "es-ES"
        case .fi: "fi-FI"
        case .fr: "fr-FR"
        case .gb: "en-GB"
        case .hk: "zh-HK"
        case .hr: "hr-HR"
        case .hu: "hu-HU"
        case .id: "id-ID"
        case .ie: "en-IE"
        case .india: "hi-IN"
        case .it: "it-IT"
        case .jp: "ja-JP"
        case .kr: "ko-KR"
        case .lt: "lt-LT"
        case .mx: "es-MX"
        case .nl: "nl-NL"
        case .no: "nb-NO"
        case .nz: "en-NZ"
        case .ph: "en-PH"
        case .pl: "pl-PL"
        case .pt: "pt-PT"
        case .rs: "sr-RS"
        case .se: "sv-SE"
        case .sk: "sk-SK"
        case .tr: "tr-TR"
        case .us: "en-US"
        case .za: "en-ZA"
        case .il: "he-IL"
        }
    }
}
