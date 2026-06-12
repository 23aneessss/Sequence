//
//  ContinuityStripView.swift
//  Sequence
//
//  A 7-day gliding window of combined consistency across all habits.
//  Reference: app_concept.md §8.1 (Horizontal Continuity Grid).
//

import SwiftUI

struct ContinuityStripView: View {
    let habits: [Habit]

    private let intensity = IntensityEngine()
    private let calendar = Calendar.sequence

    /// For each of the last 7 days: the fraction of habits reaching full completion.
    private func cell(forOffset offset: Int) -> (date: Date, level: IntensityLevel) {
        let today = Date.now.normalizedDay(calendar)
        let date = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
        guard !habits.isEmpty else { return (date, .empty) }
        let completed = habits.filter { intensity.level(for: $0, on: date) >= .full }.count
        let level = intensity.taskLevel(completed: completed, total: habits.count)
        return (date, level)
    }

    var body: some View {
        HStack(spacing: SequenceSpacing.item) {
            ForEach((0..<7).reversed(), id: \.self) { offset in
                let day = cell(forOffset: offset)
                VStack(spacing: SequenceSpacing.half) {
                    RoundedRectangle(cornerRadius: SequenceRadius.small, style: .continuous)
                        .fill(ColorScaleEngine.color(forHex: DefaultPalette.defaultHex, level: day.level))
                        .frame(height: 34)
                    Text(day.date.formatted(.dateTime.weekday(.narrow)))
                        .sequenceTextStyle(.subtext)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(SequenceSpacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: SequenceRadius.card, style: .continuous)
                .fill(SequenceColor.surfacePrimary)
        )
    }
}
