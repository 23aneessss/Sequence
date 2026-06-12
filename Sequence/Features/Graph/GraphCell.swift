//
//  GraphCell.swift
//  Sequence
//
//  One day in the Sequence (contribution) graph. Reference: app_concept.md §2.
//

import Foundation

struct GraphCell: Identifiable, Equatable {
    /// Normalized day — also the stable identity for the SwiftUI grid.
    let date: Date
    let level: IntensityLevel
    let value: Double
    /// False for week-alignment padding cells (before the window or in the future).
    let isInRange: Bool

    var id: Date { date }

    /// A padding slot rendered faintly to keep every week column 7 tall.
    static func padding(_ date: Date) -> GraphCell {
        GraphCell(date: date, level: .empty, value: 0, isInRange: false)
    }
}
