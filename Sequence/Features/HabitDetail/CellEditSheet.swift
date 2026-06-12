//
//  CellEditSheet.swift
//  Sequence
//
//  Quick-edit a past day's entry (long-press a graph cell).
//  Reference: app_concept.md §2.3.
//

import SwiftUI

struct CellEditSheet: View {
    let habit: Habit
    let cell: GraphCell
    let onSet: (Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text = ""

    private var dateText: String {
        cell.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SequenceSpacing.section) {
            VStack(alignment: .leading, spacing: SequenceSpacing.half) {
                Text("Edit \(habit.name)").sequenceTextStyle(.sectionHeader)
                Text(dateText).sequenceTextStyle(.subtext)
            }

            if habit.type == .binary {
                HStack(spacing: SequenceSpacing.item) {
                    PrimaryButton(title: "Mark complete") { onSet(habit.dailyTarget); dismiss() }
                    PrimaryButton(title: "Clear", isEnabled: cell.value > 0) { onSet(0); dismiss() }
                }
            } else {
                TextField("0", text: $text)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(SequenceColor.textPrimary)
                    .padding(SequenceSpacing.cardPadding)
                    .background(RoundedRectangle(cornerRadius: SequenceRadius.small, style: .continuous)
                        .fill(SequenceColor.surfaceSecondary))
                PrimaryButton(title: "Save") {
                    if let value = Double(text) { onSet(max(0, value)) }
                    dismiss()
                }
            }
        }
        .padding(SequenceSpacing.screenMargin)
        .background(SequenceColor.background.ignoresSafeArea())
        .onAppear { text = cell.value > 0 ? cell.value.formatted(.number.precision(.fractionLength(0...1))) : "" }
    }
}
