//
//  DateNormalization.swift
//  Sequence
//
//  All logs and tasks are keyed to local midnight. Centralizing this avoids the
//  classic habit-tracker bug where two entries on "the same day" land in
//  different buckets due to time-of-day or timezone drift.
//

import Foundation

extension Calendar {
    /// The app's day-bucketing calendar — explicit `.current` for clarity at call sites.
    static var sequence: Calendar { .current }
}

extension Date {
    /// This date collapsed to local midnight (the canonical key for a day's data).
    func normalizedDay(_ calendar: Calendar = .sequence) -> Date {
        calendar.startOfDay(for: self)
    }

    /// Whole-day distance from `other` (positive if `self` is later).
    func dayOffset(from other: Date, _ calendar: Calendar = .sequence) -> Int {
        let a = calendar.startOfDay(for: other)
        let b = calendar.startOfDay(for: self)
        return calendar.dateComponents([.day], from: a, to: b).day ?? 0
    }

    /// True if both dates fall on the same local day.
    func isSameDay(as other: Date, _ calendar: Calendar = .sequence) -> Bool {
        calendar.isDate(self, inSameDayAs: other)
    }
}
