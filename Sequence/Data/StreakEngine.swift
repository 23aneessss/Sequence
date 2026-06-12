//
//  StreakEngine.swift
//  Sequence
//
//  Streak math. Reference: app_concept.md §2.4 (streak bar), §9.4 (threshold).
//
//  A "streak day" is any day reaching at least `minLevel` intensity (default
//  Level 1 — any activity, user-configurable per §9.4). Calendar-day based:
//  the current streak survives a not-yet-logged *today* and only breaks once a
//  full day is missed.
//

import Foundation

struct StreakEngine {

    /// Minimum intensity that counts as a streak day. Reference: app_concept.md §9.4.
    var minLevel: IntensityLevel = .minimal
    var calendar: Calendar = .sequence
    private let intensity = IntensityEngine()

    // MARK: - Public API (habit-driven)

    /// Consecutive streak days ending at today (or yesterday, if today isn't logged yet).
    func currentStreak(for habit: Habit, asOf today: Date = .now) -> Int {
        currentStreak(days: qualifyingDays(for: habit), asOf: today)
    }

    /// Longest consecutive run of streak days in the habit's history.
    func bestStreak(for habit: Habit) -> Int {
        bestStreak(days: qualifyingDays(for: habit))
    }

    /// Lifetime count of days with any activity (value > 0). Reference: app_concept.md §2.4.
    func totalActiveDays(for habit: Habit) -> Int {
        habit.activeDates.count
    }

    // MARK: - Pure set-based core (directly unit-testable)

    /// The set of normalized days that meet `minLevel` for this habit.
    func qualifyingDays(for habit: Habit) -> Set<Date> {
        var result: Set<Date> = []
        for log in habit.logs where log.value > 0 {
            if intensity.level(value: log.value, for: habit) >= minLevel {
                result.insert(log.date.normalizedDay(calendar))
            }
        }
        return result
    }

    /// Current streak from an arbitrary qualifying-day set. Anchored at today,
    /// falling back to yesterday so an unlogged today doesn't reset the count.
    func currentStreak(days: Set<Date>, asOf today: Date = .now) -> Int {
        let todayStart = today.normalizedDay(calendar)

        var anchor: Date
        if days.contains(todayStart) {
            anchor = todayStart
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: todayStart),
                  days.contains(yesterday) {
            anchor = yesterday
        } else {
            return 0
        }

        var count = 0
        var cursor = anchor
        while days.contains(cursor) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return count
    }

    /// Longest consecutive run within a qualifying-day set.
    func bestStreak(days: Set<Date>) -> Int {
        guard !days.isEmpty else { return 0 }
        let sorted = days.sorted()

        var best = 1
        var run = 1
        for i in 1..<sorted.count {
            let prev = sorted[i - 1]
            let curr = sorted[i]
            if let gap = calendar.dateComponents([.day], from: prev, to: curr).day, gap == 1 {
                run += 1
                best = max(best, run)
            } else {
                run = 1
            }
        }
        return best
    }
}
