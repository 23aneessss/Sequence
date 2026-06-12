//
//  Spacing.swift
//  Sequence
//
//  Fixed 8pt grid system + corner radii. Reference: product_design.md §4.
//
//  RULE: No arbitrary layout constants. Use these tokens everywhere.
//

import CoreGraphics

/// 8pt grid spacing tokens. Reference: product_design.md §4.1.
enum SequenceSpacing {
    /// Screen horizontal margin — 16pt.
    static let screenMargin: CGFloat = 16
    /// Card internal padding — 12pt.
    static let cardPadding: CGFloat = 12
    /// Inner item spacing — 8pt.
    static let item: CGFloat = 8
    /// Section vertical separation — 24pt.
    static let section: CGFloat = 24

    // Raw grid steps, for the rare case a multiple is needed.
    static let unit: CGFloat = 8
    static let half: CGFloat = 4
}

/// Corner radii tokens. Reference: product_design.md §4.2.
/// CONSTRAINT: always pair with `.continuous` curvature.
enum SequenceRadius {
    /// Small UI components (buttons, toggles) — 8pt.
    static let small: CGFloat = 8
    /// Main grid cards / interactive blocks — 14pt.
    static let card: CGFloat = 14
}
