//
//  StreakBarView.swift
//  Sequence
//
//  Current / best / total summary shown with a habit's full graph.
//  Reference: app_concept.md §2.4.
//

import SwiftUI

struct StreakBarView: View {
    let habit: Habit
    @Environment(SettingsStore.self) private var settings
    private var streak: StreakEngine { settings.makeStreakEngine() }

    var body: some View {
        HStack(spacing: SequenceSpacing.item) {
            metric(value: "\(streak.currentStreak(for: habit))", label: "Current", showFlame: true)
            divider
            metric(value: "\(streak.bestStreak(for: habit))", label: "Best")
            divider
            metric(value: "\(streak.totalActiveDays(for: habit))", label: "Active days")
        }
        .frame(maxWidth: .infinity)
        .padding(SequenceSpacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: SequenceRadius.card, style: .continuous)
                .fill(SequenceColor.surfacePrimary)
        )
    }

    private func metric(value: String, label: String, showFlame: Bool = false) -> some View {
        VStack(spacing: SequenceSpacing.half) {
            HStack(spacing: 2) {
                if showFlame {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(SequenceColor.accentTeal)
                }
                Text(value).sequenceTextStyle(.sectionHeader)
            }
            Text(label).sequenceTextStyle(.subtext)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(SequenceColor.borderOpaque)
            .frame(width: 1, height: 28)
    }
}
