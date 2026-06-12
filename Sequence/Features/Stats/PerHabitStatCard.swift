//
//  PerHabitStatCard.swift
//  Sequence
//
//  Compact per-habit analytics row. Reference: app_concept.md §5.2.
//  Tapping opens the full habit detail.
//

import SwiftUI

struct PerHabitStatCard: View {
    let habit: Habit
    var onOpen: () -> Void

    private let stats = StatsEngine()

    var body: some View {
        let s = stats.statistics(for: habit)
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: SequenceSpacing.item) {
                header(trend: s.trend)
                MiniSparklineView(habit: habit, dayCount: 14, cellSize: 14)
                HStack(spacing: SequenceSpacing.section) {
                    stat("\(s.currentStreak)d", "Current")
                    stat("\(s.bestStreak)d", "Best")
                    stat("\(Int(s.completionRate30d))%", "30-day")
                    stat("\(s.totalActiveDays)", "Active")
                }
            }
            .padding(SequenceSpacing.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: SequenceRadius.card, style: .continuous)
                .fill(SequenceColor.surfacePrimary))
        }
        .buttonStyle(SequencePressStyle())
    }

    private func header(trend: TrendDirection) -> some View {
        HStack(spacing: SequenceSpacing.item) {
            Image(systemName: habit.iconIdentifier)
                .font(.system(size: 16))
                .foregroundStyle(Color(hex: habit.colorHex))
            Text(habit.name).sequenceTextStyle(.habitTitle)
            Spacer()
            Image(systemName: trend.symbolName)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(SequenceColor.accentTeal)
        }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).sequenceTextStyle(.habitTitle)
            Text(label).sequenceTextStyle(.subtext)
        }
    }
}
