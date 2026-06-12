//
//  Enums.swift
//  Sequence
//
//  Value types backing the SwiftData models. Reference: app_concept.md §3, §4, §10.2.
//  All are Codable so SwiftData can persist them directly.
//

import Foundation

// MARK: - Habit Type

/// The three habit tracking modes. Reference: app_concept.md §3.1.
enum HabitType: String, Codable, CaseIterable, Identifiable {
    /// Done / not done. No partial credit. Graph uses levels 0 and 4 only.
    case binary
    /// Quantified target that can be exceeded (reps, glasses, words…). Full 6 levels.
    case counted
    /// Duration-based, tracked by a timer (minutes). Full 6 levels.
    case timed

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .binary:  return "Binary"
        case .counted: return "Counted"
        case .timed:   return "Timed"
        }
    }

    /// Whether the type uses the full 6-level intensity scale (vs. empty/full only).
    var usesGradedIntensity: Bool { self != .binary }
}

// MARK: - Habit Schedule

/// When a habit is expected. Reference: app_concept.md §3.3 step 5 / §9.2.
/// Codable with associated values so SwiftData persists it as one attribute.
enum HabitSchedule: Codable, Hashable {
    /// Every day.
    case daily
    /// Specific weekdays. Uses `Calendar` weekday numbers: 1 = Sunday … 7 = Saturday.
    /// Stored as a sorted, de-duplicated array — SwiftData can't persist `Set`
    /// inside an enum's associated value.
    case weekdays([Int])
    /// Every N days from creation (N ≥ 1).
    case everyNDays(Int)

    /// Builds a `.weekdays` case from any collection, normalizing to a sorted unique array.
    static func on(_ days: some Sequence<Int>) -> HabitSchedule {
        .weekdays(Array(Set(days)).sorted())
    }

    /// Whether the habit is scheduled to occur on the given date.
    func isActive(on date: Date, createdAt: Date, calendar: Calendar = .current) -> Bool {
        switch self {
        case .daily:
            return true
        case .weekdays(let days):
            return days.contains(calendar.component(.weekday, from: date))
        case .everyNDays(let n):
            guard n >= 1 else { return false }
            let start = calendar.startOfDay(for: createdAt)
            let day = calendar.startOfDay(for: date)
            guard let diff = calendar.dateComponents([.day], from: start, to: day).day,
                  diff >= 0 else { return false }
            return diff % n == 0
        }
    }
}

// MARK: - Task Priority

/// Priority badge for a daily task. Reference: app_concept.md §4.3.
enum TaskPriority: String, Codable, CaseIterable, Identifiable {
    case low
    case medium
    case high

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .low:    return "Low"
        case .medium: return "Medium"
        case .high:   return "High"
        }
    }

    /// Higher value sorts first when ordering a task board.
    var sortWeight: Int {
        switch self {
        case .high:   return 2
        case .medium: return 1
        case .low:    return 0
        }
    }
}
