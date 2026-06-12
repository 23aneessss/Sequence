//
//  Animations.swift
//  Sequence
//
//  Bespoke spring curves. Reference: product_design.md §5.1.
//
//  RULE: `.easeInOut` and `.linear` are BANNED for interactive change.
//  Every interactive movement must use one of these engineered springs.
//

import SwiftUI

extension Animation {

    /// Structural transformations — e.g. expanding a habit card into its detail view.
    static let sequenceStructural = Animation.spring(
        response: 0.38,
        dampingFraction: 0.78,
        blendDuration: 0
    )

    /// Micro-interactions — e.g. logging a habit, button presses, checkmark toggles.
    static let sequenceMicro = Animation.spring(
        response: 0.22,
        dampingFraction: 0.65,
        blendDuration: 0
    )

    /// Fluid contextual transitions — e.g. switching tabs, staggered graph reveal.
    static let sequenceFluid = Animation.spring(
        response: 0.42,
        dampingFraction: 0.85,
        blendDuration: 0
    )
}
