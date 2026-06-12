//
//  MomentumDashboardView.swift
//  Sequence
//
//  The headline momentum score with a 30-day mini contribution grid.
//  Reference: app_concept.md §5.1.
//

import SwiftUI

struct MomentumDashboardView: View {
    let habits: [Habit]
    var weekStartsOn: Int = 1

    private let stats = StatsEngine()

    private var score: Double { stats.momentumScore(habits: habits) }

    private var miniCells: [GraphCell] {
        let rates = stats.combinedCompletion(habits: habits, dayCount: 30)
        let dayValues = rates.reduce(into: [Date: (level: IntensityLevel, value: Double)]()) { dict, pair in
            dict[pair.key] = (IntensityEngine().taskLevel(completionRate: pair.value), pair.value * 100)
        }
        return ContributionGraphBuilder(weekStartsOn: weekStartsOn).cells(dayValues: dayValues, dayCount: 30)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SequenceSpacing.item) {
            Text("Momentum").sequenceTextStyle(.subtext)
            Text(score.formatted(.number.precision(.fractionLength(0...1))))
                .font(.system(size: 52, weight: .bold))
                .foregroundStyle(SequenceColor.textPrimary)
            miniGrid
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SequenceSpacing.section)
        .background(RoundedRectangle(cornerRadius: SequenceRadius.card, style: .continuous)
            .fill(SequenceColor.surfacePrimary))
    }

    private var miniGrid: some View {
        let cellSize: CGFloat = 12, spacing: CGFloat = 3
        let rows = Array(repeating: GridItem(.fixed(cellSize), spacing: spacing), count: 7)
        return LazyHGrid(rows: rows, spacing: spacing) {
            ForEach(miniCells) { cell in
                GraphCellView(cell: cell, colorHex: DefaultPalette.defaultHex, size: cellSize)
            }
        }
        .frame(height: cellSize * 7 + spacing * 6)
    }
}
