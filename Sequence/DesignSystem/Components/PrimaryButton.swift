//
//  PrimaryButton.swift
//  Sequence
//
//  Full-width primary confirmation control. Reference: product_design.md §8.2.
//  accentTeal fill, 8pt continuous radius, light spring scale on press, haptic.
//

import SwiftUI
import UIKit

/// Button style that applies the Sequence press behaviour: a `.sequenceMicro`
/// scale-down while pressed, returning on release.
struct SequencePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.sequenceMicro, value: configuration.isPressed)
    }
}

/// The app's primary call-to-action. Lives in the lower 60% of screens (§6.1).
struct PrimaryButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Text(title)
                .sequenceTextStyle(.habitTitle)
                .foregroundStyle(SequenceColor.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, SequenceSpacing.item + SequenceSpacing.half)
                .background(
                    RoundedRectangle(cornerRadius: SequenceRadius.small, style: .continuous)
                        .fill(SequenceColor.accentTeal)
                )
                .opacity(isEnabled ? 1.0 : 0.4)
        }
        .buttonStyle(SequencePressStyle())
        .disabled(!isEnabled)
    }
}

#Preview {
    VStack(spacing: SequenceSpacing.item) {
        PrimaryButton(title: "Start Sequence") {}
        PrimaryButton(title: "Disabled", isEnabled: false) {}
    }
    .padding(SequenceSpacing.screenMargin)
    .background(SequenceColor.background)
}
