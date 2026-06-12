//
//  ColorScaleEngine.swift
//  Sequence
//
//  Generates a habit's 6-level intensity colour scale from a single base colour.
//  Reference: app_concept.md §9.3.
//
//  Mapping (HSB):
//    • Level 0 — the empty-cell token (`surfaceSecondary`), not derived from base.
//    • Levels 1–4 — saturation climbs from a light tint toward the full base,
//      while brightness eases down from near-white toward the base brightness.
//    • Level 5 — full saturation with brightness nudged darker for a "richer"
//      overachieved cell.
//

import SwiftUI
import UIKit

enum ColorScaleEngine {

    /// HSB components of a colour.
    struct HSB: Equatable {
        var hue: CGFloat
        var saturation: CGFloat
        var brightness: CGFloat
        var alpha: CGFloat
    }

    /// Decomposes a hex string into HSB components.
    static func hsb(fromHex hex: String) -> HSB {
        let ui = UIColor(hex: hex)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return HSB(hue: h, saturation: s, brightness: b, alpha: a)
    }

    /// The colour for a single intensity level (0…5) derived from `hex`.
    static func color(forHex hex: String, level: IntensityLevel) -> Color {
        guard level != .empty else { return SequenceColor.surfaceSecondary }

        let base = hsb(fromHex: hex)

        if level == .overachieved {
            // Richest/darkest cell: full saturation, slightly dimmed brightness.
            return Color(hue: base.hue,
                         saturation: min(1.0, base.saturation),
                         brightness: base.brightness * 0.82)
        }

        // Levels 1–4 → fraction 0.25 … 1.0 of the way to the full base colour.
        let fraction = CGFloat(level.rawValue) / 4.0
        let saturation = base.saturation * (0.28 + 0.72 * fraction)
        // Lower levels sit closer to white (higher brightness), easing to base at L4.
        let brightness = base.brightness + (1.0 - base.brightness) * (1.0 - fraction) * 0.55

        return Color(hue: base.hue,
                     saturation: max(0, min(1, saturation)),
                     brightness: max(0, min(1, brightness)))
    }

    /// The full 6-entry scale, indexable by `IntensityLevel.rawValue` (0…5).
    static func scale(forHex hex: String) -> [Color] {
        IntensityLevel.allCases.map { color(forHex: hex, level: $0) }
    }
}
