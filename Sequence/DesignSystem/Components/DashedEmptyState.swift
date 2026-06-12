//
//  DashedEmptyState.swift
//  Sequence
//
//  Zero-state minimalism. Reference: product_design.md §6.2.
//  Typography only — no clip-art, no illustrations. Bounded by a clean dashed
//  box using the exact `borderOpaque` token.
//

import SwiftUI

struct DashedEmptyState: View {
    let title: String
    var message: String? = nil

    var body: some View {
        VStack(spacing: SequenceSpacing.item) {
            Text(title)
                .sequenceTextStyle(.sectionHeader)
                .multilineTextAlignment(.center)

            if let message {
                Text(message)
                    .sequenceTextStyle(.subtext)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(SequenceSpacing.section)
        .background(
            RoundedRectangle(cornerRadius: SequenceRadius.card, style: .continuous)
                .strokeBorder(
                    SequenceColor.borderOpaque,
                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 5])
                )
        )
    }
}

#Preview {
    DashedEmptyState(
        title: "No habits yet",
        message: "Tap + to start your first Sequence."
    )
    .padding(SequenceSpacing.screenMargin)
    .background(SequenceColor.background)
}
