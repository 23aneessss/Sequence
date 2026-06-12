//
//  SequenceCheckmarkButton.swift
//  Sequence
//
//  The completion toggle. Reference: product_design.md §5.2.
//  Physically-rewarding interaction: haptic + success feedback + micro scale pulse.
//

import SwiftUI
import UIKit

/// A button-style that performs no visual decoration of its own, so the
/// checkmark's bespoke scale animation is the only motion the user sees.
struct NoOpButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

/// The visual core of the checkmark — an outlined circle that fills with the
/// success token and reveals a checkmark glyph when completed.
private struct ZStyleCheckmark: View {
    let isCompleted: Bool

    private let diameter: CGFloat = 28

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    isCompleted ? SequenceColor.mintTeal : SequenceColor.borderOpaque,
                    lineWidth: 2
                )
                .background(
                    Circle().fill(isCompleted ? SequenceColor.mintTeal : .clear)
                )
                .frame(width: diameter, height: diameter)

            Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(SequenceColor.background)
                .opacity(isCompleted ? 1 : 0)
                .scaleEffect(isCompleted ? 1 : 0.4)
        }
        .animation(.sequenceMicro, value: isCompleted)
    }
}

/// Completion toggle with tactile feedback. Drop-in for binary habits and tasks.
struct SequenceCheckmarkButton: View {
    var isCompleted: Bool
    var action: () -> Void

    @State private var animateTrigger = false

    var body: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.prepare()
            impact.impactOccurred()

            action()
            animateTrigger.toggle()
        } label: {
            ZStyleCheckmark(isCompleted: isCompleted)
        }
        .buttonStyle(NoOpButtonStyle())
        .sensoryFeedback(.success, trigger: animateTrigger)
        .scaleEffect(animateTrigger ? 0.92 : 1.0)
        .animation(.sequenceMicro, value: animateTrigger)
        .accessibilityLabel("Toggle completion")
        .accessibilityAddTraits(isCompleted ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview {
    struct Demo: View {
        @State private var done = false
        var body: some View {
            SequenceCheckmarkButton(isCompleted: done) { done.toggle() }
                .padding()
        }
    }
    return Demo()
}
