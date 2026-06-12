//
//  SequenceColor.swift
//  Sequence
//
//  The single source of truth for all color in the app.
//  Reference: product_design.md §2.1 / §2.2 / §2.3.
//
//  RULE: Views must use `SequenceColor.*` tokens — never raw hex.
//  Dynamic tokens adapt automatically to light/dark; brand tokens are static.
//

import SwiftUI
import UIKit

enum SequenceColor {

    // MARK: - Brand Core (always static, identical in light & dark)

    /// Primary branding anchor.
    static let navySlate = Color(hex: "303E4A")
    /// Success / complete states / momentum.
    static let mintTeal = Color(hex: "6BEFBF")
    /// Interactive items, active selection.
    static let accentTeal = Color(hex: "48A69E")

    // MARK: - System Adaptability (dynamic light/dark tokens)

    /// Primary screen background. Light #FFFFFF · Dark #0D1117.
    static let background = dynamic(light: "FFFFFF", dark: "0D1117")

    /// Primary card / elevated surfaces. Light #F6F8FA · Dark #161B22.
    static let surfacePrimary = dynamic(light: "F6F8FA", dark: "161B22")

    /// Secondary surfaces, subtle fills, empty cells. Light #EAEEF2 · Dark #21262D.
    static let surfaceSecondary = dynamic(light: "EAEEF2", dark: "21262D")

    /// Primary text content. Light #24292F · Dark #E6EDF3.
    static let textPrimary = dynamic(light: "24292F", dark: "E6EDF3")

    /// Secondary text, metadata. Light #656D76 · Dark #8B949E.
    static let textSecondary = dynamic(light: "656D76", dark: "8B949E")

    /// Borders, dividers, outlines. Light #D0D7DE · Dark #30363D.
    static let borderOpaque = dynamic(light: "D0D7DE", dark: "30363D")

    // MARK: - Dynamic Builder

    /// Builds a `Color` that resolves per `userInterfaceStyle` at render time.
    private static func dynamic(light: String, dark: String) -> Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(hex: dark)
                : UIColor(hex: light)
        })
    }
}

// MARK: - Hex Initializers

extension Color {
    /// Initializes a `Color` from a 6-digit RGB hex string (with or without `#`).
    /// Falls back to black on malformed input rather than crashing.
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let rgb = Int(cleaned, radix: 16) ?? 0
        let red = Double((rgb >> 16) & 0xFF) / 255.0
        let green = Double((rgb >> 8) & 0xFF) / 255.0
        let blue = Double(rgb & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}

extension UIColor {
    /// Initializes a `UIColor` from a 6-digit RGB hex string (with or without `#`).
    convenience init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let rgb = Int(cleaned, radix: 16) ?? 0
        let red = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let green = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let blue = CGFloat(rgb & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
