//
//  SeriousnessGaugeView.swift
//  Sequence
//
//  Circular gauge for the Seriousness Index. Reference: app_concept.md §5.1.
//

import SwiftUI

struct SeriousnessGaugeView: View {
    /// 0…100.
    let percent: Double

    @State private var animatedFraction: CGFloat = 0

    private var fraction: CGFloat { CGFloat(max(0, min(100, percent)) / 100) }

    var body: some View {
        VStack(spacing: SequenceSpacing.item) {
            ZStack {
                Circle()
                    .stroke(SequenceColor.surfaceSecondary, lineWidth: 12)
                Circle()
                    .trim(from: 0, to: animatedFraction)
                    .stroke(SequenceColor.accentTeal,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text("\(Int(percent))%").sequenceTextStyle(.appTitle)
                    Text("serious").sequenceTextStyle(.subtext)
                }
            }
            .frame(width: 140, height: 140)

            Text("Days active in the last 90").sequenceTextStyle(.subtext)
        }
        .frame(maxWidth: .infinity)
        .padding(SequenceSpacing.section)
        .background(RoundedRectangle(cornerRadius: SequenceRadius.card, style: .continuous)
            .fill(SequenceColor.surfacePrimary))
        .onAppear { withAnimation(.sequenceFluid) { animatedFraction = fraction } }
        .onChange(of: fraction) { _, new in withAnimation(.sequenceFluid) { animatedFraction = new } }
    }
}
