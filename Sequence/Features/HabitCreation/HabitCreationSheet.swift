//
//  HabitCreationSheet.swift
//  Sequence
//
//  Bottom-sheet habit builder. Reference: app_concept.md §3.3, product_design.md §8.2.
//  A live preview card sits atop the sectioned form. Body stays lean by delegating
//  each section to a focused subview.
//

import SwiftUI

struct HabitCreationSheet: View {
    @Environment(SequenceRepository.self) private var repo
    @Environment(NotificationManager.self) private var notifications
    @Environment(\.dismiss) private var dismiss
    @State private var form = HabitFormModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SequenceSpacing.section) {
                previewCard
                HabitNameIconSection(form: form)
                HabitTypeSection(form: form)
                HabitColorSection(form: form)
                if form.type != .binary { HabitTargetSection(form: form) }
                HabitScheduleSection(form: form)
                HabitReminderSection(form: form)
                PrimaryButton(title: "Create habit", isEnabled: form.isValid) {
                    form.create(using: repo)
                    Task { await notifications.rescheduleAll() }
                    dismiss()
                }
            }
            .padding(SequenceSpacing.screenMargin)
        }
        .background(SequenceColor.background.ignoresSafeArea())
    }

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: SequenceSpacing.item) {
            HStack(spacing: SequenceSpacing.item) {
                Image(systemName: form.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(Color(hex: form.colorHex))
                Text(form.name.isEmpty ? "New habit" : form.name).sequenceTextStyle(.habitTitle)
                Spacer()
                Circle().fill(Color(hex: form.colorHex)).frame(width: 12, height: 12)
            }
            HStack(spacing: SequenceSpacing.half) {
                ForEach(1...5, id: \.self) { level in
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(ColorScaleEngine.color(forHex: form.colorHex,
                                                     level: IntensityLevel(rawValue: level) ?? .full))
                        .frame(width: 18, height: 18)
                }
            }
        }
        .padding(SequenceSpacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: SequenceRadius.card, style: .continuous)
            .fill(SequenceColor.surfacePrimary))
    }
}
