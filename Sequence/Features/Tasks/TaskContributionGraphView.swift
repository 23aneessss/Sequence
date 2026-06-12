//
//  TaskContributionGraphView.swift
//  Sequence
//
//  The unified Task Contribution Graph. Reference: app_concept.md §4.2.
//  Each day's cell intensity reflects that day's task completion rate; a 100%
//  "Perfect Day" gets a distinctive accent ring.
//

import SwiftUI

struct TaskContributionGraphView: View {
    let completionRates: [Date: Double]
    var weekStartsOn: Int = 1
    var dayCount: Int = 365

    private let intensity = IntensityEngine()
    private let colorHex = DefaultPalette.defaultHex

    private var builder: ContributionGraphBuilder {
        ContributionGraphBuilder(weekStartsOn: weekStartsOn)
    }

    private var cells: [GraphCell] {
        let dayValues = completionRates.reduce(into: [Date: (level: IntensityLevel, value: Double)]()) { dict, pair in
            dict[pair.key.normalizedDay()] = (intensity.taskLevel(completionRate: pair.value), pair.value * 100)
        }
        return builder.cells(dayValues: dayValues, dayCount: dayCount)
    }

    var body: some View {
        let cellSize: CGFloat = 11
        let spacing: CGFloat = 3
        let rows = Array(repeating: GridItem(.fixed(cellSize), spacing: spacing), count: builder.rowCount)

        ScrollView(.horizontal, showsIndicators: false) {
            LazyHGrid(rows: rows, spacing: spacing) {
                ForEach(cells) { cell in
                    GraphCellView(cell: cell, colorHex: colorHex, size: cellSize)
                        .overlay {
                            if cell.isInRange && cell.level == .overachieved {
                                RoundedRectangle(cornerRadius: cellSize * 0.22, style: .continuous)
                                    .strokeBorder(SequenceColor.mintTeal, lineWidth: 1.5)
                            }
                        }
                }
            }
            .padding(.trailing, SequenceSpacing.half)
        }
        .defaultScrollAnchor(.trailing)
    }
}
