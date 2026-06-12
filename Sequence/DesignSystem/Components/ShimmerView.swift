//
//  ShimmerView.swift
//  Sequence
//
//  Skeleton loading. Reference: product_design.md §6.2.
//  A linear gradient sweeping continuously across a surface — never a blocking
//  modal spinner.
//
//  NOTE on motion policy (§5.1): the ban on `.linear`/`.easeInOut` applies to
//  *interactive* state change. A shimmer is an ambient, non-interactive loop with
//  no spring rest state, so a continuous linear phase is the correct idiom here.
//

import SwiftUI

/// A redacted-style placeholder block that sweeps a highlight across itself.
struct ShimmerView: View {
    var cornerRadius: CGFloat = SequenceRadius.small

    @State private var phase: CGFloat = -1

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(SequenceColor.surfaceSecondary)
            .overlay {
                GeometryReader { geo in
                    let highlight = LinearGradient(
                        colors: [
                            .clear,
                            SequenceColor.surfacePrimary.opacity(0.9),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(highlight)
                        .offset(x: phase * geo.size.width)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .onAppear {
                withAnimation(.linear(duration: 1.25).repeatForever(autoreverses: false)) {
                    phase = 1.5
                }
            }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: SequenceSpacing.item) {
        ShimmerView().frame(height: 18)
        ShimmerView().frame(width: 180, height: 18)
        ShimmerView(cornerRadius: SequenceRadius.card).frame(height: 64)
    }
    .padding(SequenceSpacing.screenMargin)
    .background(SequenceColor.background)
}
