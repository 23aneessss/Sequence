//
//  MiniSparklineView.swift
//  Sequence
//
//  The always-visible last-7-days strip on a habit card. Reference: app_concept.md §3.2.
//

import SwiftUI

struct MiniSparklineView: View {
    let habit: Habit
    var dayCount: Int = 7
    var cellSize: CGFloat = 16

    private let intensity = IntensityEngine()

    private var days: [GraphCell] {
        let calendar = Calendar.sequence
        let today = Date.now.normalizedDay(calendar)
        return (0..<dayCount).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            let value = habit.value(on: date, calendar)
            return GraphCell(date: date, level: intensity.level(value: value, for: habit),
                             value: value, isInRange: true)
        }
    }

    var body: some View {
        HStack(spacing: SequenceSpacing.half) {
            ForEach(days) { cell in
                GraphCellView(cell: cell, colorHex: habit.colorHex, size: cellSize)
            }
        }
        .accessibilityLabel("Last \(dayCount) days")
    }
}
