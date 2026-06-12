//
//  StatsEngine.swift
//  Sequence
//
//  Analytics computations. Reference: app_concept.md §5.
//  Pure functions over habits + their logs; the Stats UI renders these directly
//  and never recomputes business logic itself.
//

import Foundation

/// 14-day momentum direction. Reference: app_concept.md §5.2 (Trend Arrow).
enum TrendDirection {
    case up, down, flat

    var symbolName: String {
        switch self {
        case .up:   return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .flat: return "arrow.right"
        }
    }
}

/// The full per-habit metric set shown on a habit's statistics card.
/// Reference: app_concept.md §5.2.
struct HabitStatistics {
    let currentStreak: Int
    let bestStreak: Int
    let totalActiveDays: Int
    let completionRate30d: Double      // 0…100
    let completionRateAllTime: Double  // 0…100
    let averageDailyCount: Double      // over active days; 0 if none
    let bestDayEver: Double
    let totalLifetimeVolume: Double
    let trend: TrendDirection
}

struct StatsEngine {

    var calendar: Calendar = .sequence
    var streak = StreakEngine()
    private let intensity = IntensityEngine()

    // MARK: - Per-habit

    func statistics(for habit: Habit, asOf today: Date = .now) -> HabitStatistics {
        HabitStatistics(
            currentStreak: streak.currentStreak(for: habit, asOf: today),
            bestStreak: streak.bestStreak(for: habit),
            totalActiveDays: streak.totalActiveDays(for: habit),
            completionRate30d: completionRate(for: habit, lastDays: 30, asOf: today),
            completionRateAllTime: completionRateAllTime(for: habit, asOf: today),
            averageDailyCount: averageDailyCount(for: habit),
            bestDayEver: habit.logs.map(\.value).max() ?? 0,
            totalLifetimeVolume: habit.totalVolume,
            trend: trend(for: habit, asOf: today)
        )
    }

    /// % of days in the trailing `lastDays` window that reached full completion.
    /// Denominator is bounded by the habit's creation so young habits aren't penalized.
    func completionRate(for habit: Habit, lastDays: Int, asOf today: Date = .now) -> Double {
        let todayStart = today.normalizedDay(calendar)
        guard let windowStart = calendar.date(byAdding: .day, value: -(lastDays - 1), to: todayStart) else {
            return 0
        }
        let start = max(windowStart, habit.createdAt.normalizedDay(calendar))
        return completionRate(for: habit, from: start, to: todayStart)
    }

    func completionRateAllTime(for habit: Habit, asOf today: Date = .now) -> Double {
        let todayStart = today.normalizedDay(calendar)
        let start = habit.createdAt.normalizedDay(calendar)
        return completionRate(for: habit, from: start, to: todayStart)
    }

    /// Shared completion-rate core over an inclusive [start, end] day range.
    private func completionRate(for habit: Habit, from start: Date, to end: Date) -> Double {
        guard start <= end,
              let totalDays = calendar.dateComponents([.day], from: start, to: end).day else {
            return 0
        }
        let denominator = totalDays + 1
        guard denominator > 0 else { return 0 }

        let completed = habit.logs.filter { log in
            log.date >= start && log.date <= end &&
            intensity.level(value: log.value, for: habit) >= .full
        }.count

        return Double(completed) / Double(denominator) * 100
    }

    /// Mean value over days that had any activity. 0 when there are none.
    func averageDailyCount(for habit: Habit) -> Double {
        let active = habit.logs.filter { $0.value > 0 }
        guard !active.isEmpty else { return 0 }
        return active.reduce(0) { $0 + $1.value } / Double(active.count)
    }

    /// Compares the last 14 days' volume against the prior 14 days. §5.2.
    func trend(for habit: Habit, asOf today: Date = .now) -> TrendDirection {
        let recent = volume(for: habit, endingDaysAgo: 0, window: 14, asOf: today)
        let prior = volume(for: habit, endingDaysAgo: 14, window: 14, asOf: today)
        if recent > prior { return .up }
        if recent < prior { return .down }
        return .flat
    }

    /// Sum of values over a `window`-day span ending `endingDaysAgo` days before today.
    private func volume(for habit: Habit, endingDaysAgo: Int, window: Int, asOf today: Date) -> Double {
        let todayStart = today.normalizedDay(calendar)
        guard let end = calendar.date(byAdding: .day, value: -endingDaysAgo, to: todayStart),
              let start = calendar.date(byAdding: .day, value: -(window - 1), to: end) else {
            return 0
        }
        return habit.logs
            .filter { $0.date >= start && $0.date <= end }
            .reduce(0) { $0 + $1.value }
    }

    // MARK: - Macro metrics

    /// Aggregate momentum across all active habits. Reference: app_concept.md §5.1.
    /// Weighted average of (current streak × frequency weight) over active habits.
    func momentumScore(habits: [Habit], asOf today: Date = .now) -> Double {
        let active = habits.filter { !$0.isArchived }
        let weightTotal = active.reduce(0.0) { $0 + $1.frequencyWeight }
        guard weightTotal > 0 else { return 0 }

        let weighted = active.reduce(0.0) { sum, habit in
            sum + Double(streak.currentStreak(for: habit, asOf: today)) * habit.frequencyWeight
        }
        return weighted / weightTotal
    }

    /// Per-day combined completion rate (0…1) across habits — the fraction of
    /// habits reaching full completion that day. Feeds the momentum mini-grid.
    func combinedCompletion(habits: [Habit], dayCount: Int, asOf today: Date = .now) -> [Date: Double] {
        let active = habits.filter { !$0.isArchived }
        guard !active.isEmpty else { return [:] }
        let todayStart = today.normalizedDay(calendar)
        var result: [Date: Double] = [:]
        for offset in 0..<dayCount {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: todayStart) else { continue }
            let completed = active.filter { intensity.level(for: $0, on: date) >= .full }.count
            result[date] = Double(completed) / Double(active.count)
        }
        return result
    }

    /// Ratio of days in the lookback window with ≥1 habit active. Reference: app_concept.md §5.1.
    /// Returns 0…100.
    func seriousnessIndex(habits: [Habit], lookbackDays days: Int = 90, asOf today: Date = .now) -> Double {
        guard days > 0 else { return 0 }
        let todayStart = today.normalizedDay(calendar)

        // Union of every habit's active days, then keep those inside the window.
        let allActive = habits.reduce(into: Set<Date>()) { $0.formUnion($1.activeDates) }
        let activeInWindow = allActive.filter { day in
            guard let offset = calendar.dateComponents([.day], from: day, to: todayStart).day else { return false }
            return offset >= 0 && offset < days
        }
        return Double(activeInWindow.count) / Double(days) * 100
    }
}
