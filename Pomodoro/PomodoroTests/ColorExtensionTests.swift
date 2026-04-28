//
//  ColorExtensionTests.swift
//  PomodoroTests
//

import Testing
import SwiftUI
import UIKit
@testable import Pomodoro

@Suite struct ColorExtensionTests {
    private func components(_ color: Color) -> (r: CGFloat, g: CGFloat, b: CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b)
    }

    @Test func parsesPureRedWithHashPrefix() {
        let c = components(Color(hex: "#FF0000"))
        #expect(c.r == 1.0)
        #expect(c.g == 0.0)
        #expect(c.b == 0.0)
    }

    @Test func parsesPureGreen() {
        let c = components(Color(hex: "#00FF00"))
        #expect(c.r == 0.0)
        #expect(c.g == 1.0)
        #expect(c.b == 0.0)
    }

    @Test func parsesPureBlue() {
        let c = components(Color(hex: "#0000FF"))
        #expect(c.r == 0.0)
        #expect(c.g == 0.0)
        #expect(c.b == 1.0)
    }

    @Test func parsesBlack() {
        let c = components(Color(hex: "#000000"))
        #expect(c.r == 0.0)
        #expect(c.g == 0.0)
        #expect(c.b == 0.0)
    }

    @Test func parsesWhite() {
        let c = components(Color(hex: "#FFFFFF"))
        #expect(c.r == 1.0)
        #expect(c.g == 1.0)
        #expect(c.b == 1.0)
    }

    @Test func acceptsHexWithoutHashPrefix() {
        let withHash = components(Color(hex: "#FF9500"))
        let withoutHash = components(Color(hex: "FF9500"))
        #expect(withHash.r == withoutHash.r)
        #expect(withHash.g == withoutHash.g)
        #expect(withHash.b == withoutHash.b)
    }

    @Test func acceptsLowercaseHex() {
        let upper = components(Color(hex: "#AF52DE"))
        let lower = components(Color(hex: "#af52de"))
        #expect(upper.r == lower.r)
        #expect(upper.g == lower.g)
        #expect(upper.b == lower.b)
    }

    @Test func categoryColorsCatalogIsPopulated() {
        #expect(Color.categoryColors.count == 8)
        for entry in Color.categoryColors {
            #expect(!entry.name.isEmpty)
            #expect(entry.hex.hasPrefix("#"))
            #expect(entry.hex.count == 7)
        }
    }
}
