//
//  BulkInputView.swift
//  Sequence
//
//  Numeric entry for counted habits (long-press the + button).
//  Reference: app_concept.md §3.1 (Type B — bulk entry).
//

import SwiftUI

struct BulkInputView: View {
    let habit: Habit
    let currentValue: Double
    let onSet: (Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: SequenceSpacing.section) {
            VStack(alignment: .leading, spacing: SequenceSpacing.half) {
                Text("Set \(habit.name)").sequenceTextStyle(.sectionHeader)
                Text("Today's total \(habit.unit.map { "in \($0)" } ?? "")").sequenceTextStyle(.subtext)
            }

            TextField("0", text: $text)
                .keyboardType(.decimalPad)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(SequenceColor.textPrimary)
                .padding(SequenceSpacing.cardPadding)
                .background(
                    RoundedRectangle(cornerRadius: SequenceRadius.small, style: .continuous)
                        .fill(SequenceColor.surfaceSecondary)
                )

            PrimaryButton(title: "Save") {
                if let value = Double(text) { onSet(max(0, value)) }
                dismiss()
            }
        }
        .padding(SequenceSpacing.screenMargin)
        .background(SequenceColor.background.ignoresSafeArea())
        .onAppear { text = currentValue > 0 ? currentValue.formatted(.number.precision(.fractionLength(0...1))) : "" }
    }
}
