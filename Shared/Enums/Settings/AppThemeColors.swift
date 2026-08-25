//
//  AppThemeColors.swift
//  Cronica
//
//  Created by Alexandre Madeira on 18/12/22.
//

import SwiftUI

enum AppThemeColors: Int, Identifiable, CaseIterable {
    var id: Int { rawValue }
    case blue = 0
    case red = 1
    case green = 2
    case brown = 3
    case cyan = 4
    case gray = 5
    case indigo = 6
    case mint = 7
    case orange = 8
    case pink = 9
    case purple = 10
    case teal = 11
    case yellow = 12
    case steel = 13
    case roseGold = 14
    case turquoise = 15
    case lavender = 16
    case cherry = 17
    case skyBlue = 18
    case goldenrod = 19
    case coral = 20
    case turquoiseBlue = 21
    case rubyRed = 22
    case mahoganyBrown = 23
    case burntOrange = 24
    case fireballRed = 25
    case mysticTeal = 26
    case electricBlue = 27

    var color: Color {
        switch self {
        case .blue: .blue
        case .red: .red
        case .green: .green
        case .brown: .brown
        case .cyan: .cyan
        case .gray: .gray
        case .indigo: .indigo
        case .mint: .mint
        case .orange: .orange
        case .pink: .pink
        case .purple: .purple
        case .teal: .teal
        case .yellow: .yellow
        case .steel: Color(red: 0.57, green: 0.64, blue: 0.69)
        case .roseGold: Color(red: 0.91, green: 0.71, blue: 0.71)
        case .turquoise: Color(red: 0.0, green: 0.78, blue: 0.67)
        case .lavender: Color(red: 0.69, green: 0.49, blue: 0.86)
        case .cherry: Color(red: 0.8, green: 0.12, blue: 0.24)
        case .skyBlue: Color(red: 0.53, green: 0.81, blue: 0.98)
        case .goldenrod: Color(red: 0.85, green: 0.65, blue: 0.13)
        case .coral: Color(red: 1.0, green: 0.5, blue: 0.31)
        case .turquoiseBlue: Color(red: 0.0, green: 0.73, blue: 0.83)
        case .rubyRed: Color(red: 0.69, green: 0.09, blue: 0.19)
        case .mahoganyBrown: Color(red: 0.54, green: 0.27, blue: 0.07)
        case .burntOrange: Color(red: 0.8, green: 0.33, blue: 0.0)
        case .fireballRed: Color(red: 0.93, green: 0.16, blue: 0.16)
        case .mysticTeal: Color(red: 0.0, green: 0.6, blue: 0.6)
        case .electricBlue: Color(red: 0.0, green: 0.69, blue: 0.96)
        }
    }

    var title: String {
        switch self {
        case .blue: String(localized: "Blue")
        case .red: String(localized: "Red")
        case .green: String(localized: "Green")
        case .brown: String(localized: "Brown")
        case .cyan: String(localized: "Cyan")
        case .gray: String(localized: "Gray")
        case .indigo: String(localized: "Indigo")
        case .mint: String(localized: "Mint")
        case .orange: String(localized: "Orange")
        case .pink: String(localized: "Pink")
        case .purple: String(localized: "Purple")
        case .teal: String(localized: "Teal")
        case .yellow: String(localized: "Yellow")
        case .steel: String(localized: "Steel")
        case .roseGold: String(localized: "Rose Gold")
        case .turquoise: String(localized: "Turquoise")
        case .lavender: String(localized: "Lavender")
        case .cherry: String(localized: "Cherry")
        case .skyBlue: String(localized: "Sky Blue")
        case .goldenrod: String(localized: "Goldenrod")
        case .coral: String(localized: "Coral")
        case .turquoiseBlue: String(localized: "Turquoise Blue")
        case .rubyRed: String(localized: "Ruby Red")
        case .mahoganyBrown: String(localized: "Mahogany")
        case .burntOrange: String(localized: "Burnt Orange")
        case .fireballRed: String(localized: "Fireball")
        case .mysticTeal: String(localized: "Mystic Teal")
        case .electricBlue: String(localized: "Electric Blue")
        }
    }
}
