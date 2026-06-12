//
//  HabitLog.swift
//  Sequence
//
//  One aggregated entry per habit per day. Reference: app_concept.md §10.2.
//  Invariant: at most one HabitLog per (habit, normalized day) — the repository
//  upserts into the day's log rather than creating duplicates.
//

import Foundation
import SwiftData

@Model
final class HabitLog {
    @Attribute(.unique) var id: UUID

    /// The day this entry belongs to, normalized to local midnight.
    var date: Date
    /// Count / duration in minutes / 1.0 for a completed binary habit.
    var value: Double
    /// Exact timestamp of the most recent write for this day.
    var loggedAt: Date

    /// Owning habit (inverse of `Habit.logs`).
    var habit: Habit?

    init(
        id: UUID = UUID(),
        date: Date,
        value: Double,
        loggedAt: Date = .now,
        habit: Habit? = nil
    ) {
        self.id = id
        self.date = date
        self.value = value
        self.loggedAt = loggedAt
        self.habit = habit
    }
}
