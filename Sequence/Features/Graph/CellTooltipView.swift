//
//  CellTooltipView.swift
//  Sequence
//
//  Popover shown when a graph cell is tapped. Reference: app_concept.md §2.3.
//

import SwiftUI

struct CellTooltipView: View {
    let cell: GraphCell
    let unit: String?

    private var dateText: String {
        cell.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }

    private var valueText: String {
        guard cell.isInRange else { return "Outside range" }
        if cell.value <= 0 { return "No activity" }
        let number = cell.value.formatted(.number.precision(.fractionLength(0...1)))
        if let unit, !unit.isEmpty { return "\(number) \(unit)" }
        return number
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SequenceSpacing.half) {
            Text(dateText).sequenceTextStyle(.habitTitle)
            Text(valueText).sequenceTextStyle(.subtext)
            Text("Level \(cell.level.rawValue)")
                .sequenceTextStyle(.subtext)
                .foregroundStyle(SequenceColor.accentTeal)
        }
        .padding(SequenceSpacing.cardPadding)
        .presentationCompactAdaptation(.popover)
    }
}
