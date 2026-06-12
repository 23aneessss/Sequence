//
//  HabitCardView.swift
//  Sequence
//
//  A single habit on the Today dashboard. Reference: app_concept.md §3.2 (anatomy),
//  §11.2 (logging feedback), §11.3 (streak break).
//

import SwiftUI

struct HabitCardView: View {
    let habit: Habit
    var namespace: Namespace.ID
    var onOpen: () -> Void

    @Environment(SequenceRepository.self) private var repo
    @Environment(HabitTimerManager.self) private var timer
    @Environment(SettingsStore.self) private var settings

    @State private var pulse = false
    @State private var bulkEntry = false
    @State private var celebratedMilestone: Int?

    private var streakEngine: StreakEngine { settings.makeStreakEngine() }
    private let intensity = IntensityEngine()
    private static let milestones: Set<Int> = [7, 14, 30, 60, 90, 180, 365]

    private var todayValue: Double { repo.value(for: habit, on: .now) }
    private var currentStreak: Int { streakEngine.currentStreak(for: habit) }
    private var isBrokenToday: Bool { currentStreak == 0 && streakEngine.brokenStreakLength(for: habit) > 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: SequenceSpacing.item) {
            header
            MiniSparklineView(habit: habit, cellSize: 18)
            if habit.type != .binary { progressBar }
            if let celebratedMilestone { milestoneBanner(celebratedMilestone) }
        }
        .padding(SequenceSpacing.cardPadding)
        .background(cardBackground)
        .overlay(alignment: .leading) { if isBrokenToday { brokenBorder } }
        .scaleEffect(pulse ? 0.98 : 1.0)
        .matchedGeometryEffect(id: habit.id, in: namespace)
        .contentShape(RoundedRectangle(cornerRadius: SequenceRadius.card, style: .continuous))
        .onTapGesture(perform: onOpen)
        .sheet(isPresented: $bulkEntry) {
            BulkInputView(habit: habit, currentValue: todayValue) { newValue in
                repo.setValue(newValue, for: habit, on: .now)
            }
            .presentationDetents([.fraction(0.3)])
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: SequenceSpacing.item) {
            Circle().fill(Color(hex: habit.colorHex)).frame(width: 12, height: 12)
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name).sequenceTextStyle(.habitTitle)
                streakLabel
            }
            Spacer(minLength: SequenceSpacing.item)
            logControl
        }
    }

    private var streakLabel: some View {
        Group {
            if isBrokenToday {
                Text("0d (was \(streakEngine.brokenStreakLength(for: habit))d)")
                    .sequenceTextStyle(.subtext)
                    .foregroundStyle(Color(hex: "E05C5C"))
            } else {
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill").font(.system(size: 11))
                    Text("\(currentStreak)d")
                }
                .sequenceTextStyle(.subtext)
                .foregroundStyle(currentStreak > 0 ? SequenceColor.accentTeal : SequenceColor.textSecondary)
            }
        }
    }

    // MARK: - Type-specific log control

    @ViewBuilder private var logControl: some View {
        switch habit.type {
        case .binary:
            SequenceCheckmarkButton(isCompleted: todayValue >= habit.dailyTarget) { logBinary() }
        case .counted:
            countedControl
        case .timed:
            timedControl
        }
    }

    private var countedControl: some View {
        Button { incrementCounted() } label: {
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(SequenceColor.background)
                .frame(width: 36, height: 36)
                .background(Circle().fill(SequenceColor.accentTeal))
        }
        .buttonStyle(SequencePressStyle())
        .simultaneousGesture(LongPressGesture().onEnded { _ in bulkEntry = true })
    }

    private var timedControl: some View {
        Button { toggleTimer() } label: {
            Image(systemName: timer.isRunning(habit) ? "stop.fill" : "play.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(SequenceColor.background)
                .frame(width: 36, height: 36)
                .background(Circle().fill(timer.isRunning(habit) ? Color(hex: "E05C5C") : SequenceColor.accentTeal))
        }
        .buttonStyle(SequencePressStyle())
    }

    // MARK: - Progress

    private var progressBar: some View {
        let fraction = habit.dailyTarget > 0 ? min(1, todayValue / habit.dailyTarget) : 0
        return VStack(alignment: .leading, spacing: SequenceSpacing.half) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(SequenceColor.surfaceSecondary)
                    Capsule().fill(Color(hex: habit.colorHex))
                        .frame(width: max(0, geo.size.width * fraction))
                }
            }
            .frame(height: 8)
            Text(progressLabel).sequenceTextStyle(.subtext)
        }
    }

    private var progressLabel: String {
        let value = todayValue.formatted(.number.precision(.fractionLength(0...1)))
        let target = habit.dailyTarget.formatted(.number.precision(.fractionLength(0...1)))
        if habit.type == .timed {
            let live = timer.isRunning(habit) ? " · running…" : ""
            return "\(value)/\(target) min today\(live)"
        }
        let unit = habit.unit ?? ""
        return "\(value)/\(target) \(unit) today"
    }

    // MARK: - Backgrounds

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: SequenceRadius.card, style: .continuous)
            .fill(SequenceColor.surfacePrimary)
    }

    private var brokenBorder: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(Color(hex: "E05C5C").opacity(0.4))
            .frame(width: 3)
            .padding(.vertical, 6)
    }

    private func milestoneBanner(_ days: Int) -> some View {
        Text("\(days)-day streak. This is what consistency looks like.")
            .sequenceTextStyle(.subtext)
            .foregroundStyle(SequenceColor.mintTeal)
            .transition(.opacity)
    }

    // MARK: - Logging actions

    private func logBinary() {
        let before = currentStreak
        repo.toggleBinary(habit)
        firePulse()
        checkMilestone(before: before)
    }

    private func incrementCounted() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let before = currentStreak
        repo.increment(habit, by: 1)
        firePulse()
        checkMilestone(before: before)
    }

    private func toggleTimer() {
        if timer.isRunning(habit) {
            if let minutes = timer.stop(habit), minutes > 0 {
                let before = currentStreak
                repo.increment(habit, by: minutes)
                checkMilestone(before: before)
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            timer.start(habit)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        firePulse()
    }

    private func firePulse() {
        withAnimation(.sequenceMicro) { pulse = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.sequenceMicro) { pulse = false }
        }
    }

    private func checkMilestone(before: Int) {
        let after = currentStreak
        guard after > before, Self.milestones.contains(after) else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.sequenceFluid) { celebratedMilestone = after }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.sequenceFluid) { celebratedMilestone = nil }
        }
    }
}
