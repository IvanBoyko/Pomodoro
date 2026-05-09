//
//  ColorExtension.swift
//  Pomodoro
//
//  Created by fenix on 28/03/2026.
//

import SwiftUI

extension Color {
    init(hex: String) {
        let cleanHex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: cleanHex)
        var rgbValue: UInt64 = 0
        guard scanner.scanHexInt64(&rgbValue) else {
            assertionFailure("Failed to parse color hex string: \(hex)")
            self = .gray
            return
        }

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }

    static let categoryColors: [(name: String, hex: String)] = [
        ("Blue", "#007AFF"),
        ("Red", "#FF3B30"),
        ("Green", "#34C759"),
        ("Orange", "#FF9500"),
        ("Purple", "#AF52DE"),
        ("Teal", "#5AC8FA"),
        ("Pink", "#FF2D55"),
        ("Yellow", "#FFCC00"),
    ]
}
