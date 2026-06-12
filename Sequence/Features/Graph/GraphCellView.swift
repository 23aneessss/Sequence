//
//  GraphCellView.swift
//  Sequence
//
//  A single day square in the Sequence graph. Reference: app_concept.md §2.2.
//

import SwiftUI

struct GraphCellView: View {
    let cell: GraphCell
    let colorHex: String
    let size: CGFloat
    var isSelected: Bool = false

    private var fill: Color {
        guard cell.isInRange else { return SequenceColor.surfaceSecondary.opacity(0.35) }
        return ColorScaleEngine.color(forHex: colorHex, level: cell.level)
    }

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
            .fill(fill)
            .frame(width: size, height: size)
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                    .strokeBorder(
                        isSelected ? SequenceColor.accentTeal : SequenceColor.borderOpaque.opacity(0.25),
                        lineWidth: isSelected ? 2 : 0.5
                    )
            )
    }
}
