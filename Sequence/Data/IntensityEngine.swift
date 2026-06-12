//
//  IntensityEngine.swift
//  Sequence
//
//  Maps a recorded value to a 0–5 contribution-graph intensity level.
//  Reference: app_concept.md §2.2 (scale), §3.1 (per-type), §4.2 (tasks).
//
//  Stateless and pure — the contribution graph is only as trustworthy as this,
//  so it is exhaustively unit-tested at every threshold boundary.
//

import Foundation

/// The fixed 6-level intensity scale. Reference: app_concept.md §2.2.
enum IntensityLevel: Int, CaseIterable, Comparable {
    case empty = 0        // No activity
    case minimal = 1      // Activity started, threshold not met
    case low = 2          // Partial completion
    case medium = 3       // Standard completion
    case full = 4         // Full target met
    case overachieved = 5 // Exceeded daily target

    static func < (lhs: IntensityLevel, rhs: IntensityLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct IntensityEngine {

    /// The intensity level for `habit` on `date`, read from its logs.
    func level(for habit: Habit, on date: Date, _ calendar: Calendar = .sequence) -> IntensityLevel {
        level(value: habit.value(on: date, calendar), for: habit)
    }

    /// Core mapping: a raw value → level for a given habit's configuration.
    /// Separated from date lookup so it can be tested in isolation.
    func level(value: Double, for habit: Habit) -> IntensityLevel {
        guard value > 0 else { return .empty }

        // Binary habits use only empty / full.
        guard habit.type.usesGradedIntensity else {
            return value >= habit.dailyTarget ? .full : .empty
        }

        // Level 5 only exists when an overachieve target sits above the daily target.
        if habit.overachieveTarget > habit.dailyTarget,
           value >= habit.overachieveTarget {
            return .overachieved
        }
        if value >= habit.dailyTarget {
            return .full
        }

        let breakpoints = effectiveThresholds(for: habit)
        if value >= breakpoints[2] { return .medium }
        if value >= breakpoints[1] { return .low }
        if value >= breakpoints[0] { return .minimal }

        // Any nonzero progress below the first breakpoint still counts as "started".
        return .minimal
    }

    /// The breakpoints for Levels 1/2/3. Uses the user's `thresholds` when three
    /// are supplied; otherwise derives sensible 25/50/75% gates from the daily target.
    func effectiveThresholds(for habit: Habit) -> [Double] {
        if habit.thresholds.count >= 3 {
            return Array(habit.thresholds.prefix(3)).sorted()
        }
        let t = habit.dailyTarget
        return [t * 0.25, t * 0.5, t * 0.75]
    }

    // MARK: - Task Contribution Graph

    /// Maps a daily task completion rate (0…1) to an intensity level.
    /// Reference: app_concept.md §4.2.
    func taskLevel(completionRate rate: Double) -> IntensityLevel {
        switch rate {
        case ..<0.0:        return .empty   // defensive
        case 0.0:           return .empty
        case ..<0.25:       return .minimal
        case ..<0.50:       return .low
        case ..<0.75:       return .medium
        case ..<1.0:        return .full
        default:            return .overachieved // 100% — "Perfect Day"
        }
    }

    /// Convenience: completion rate from completed/total task counts.
    func taskLevel(completed: Int, total: Int) -> IntensityLevel {
        guard total > 0 else { return .empty }
        return taskLevel(completionRate: Double(completed) / Double(total))
    }
}
