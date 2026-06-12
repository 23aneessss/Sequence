//
//  Habit.swift
//  Sequence
//
//  The central data model. Reference: app_concept.md §10.2 / §3.
//  "Sequence" is the product name; the model is `Habit` (see app_plan.md §1).
//

import Foundation
import SwiftData

@Model
final class Habit: Identifiable {
    /// Stable identity, also used by notifications and exports.
    @Attribute(.unique) var id: UUID

    /// Owning account (Sign in with Apple user id). Empty for pre-auth/local data.
    /// Every fetch is scoped by this so accounts never see each other's habits.
    var ownerID: String = ""

    var name: String
    /// SF Symbol name or emoji. Reference: app_concept.md §9.2.
    var iconIdentifier: String
    /// Base color hex (no `#`). The 6-level scale is derived from this in Phase 3.
    var colorHex: String

    var type: HabitType

    /// Unit label for counted habits (reps, glasses, km…). Nil for binary/timed.
    var unit: String?
    /// Value reaching Level 4 ("Full"). For binary this is 1.0.
    var dailyTarget: Double
    /// Value reaching Level 5 ("Overachieved").
    var overachieveTarget: Double
    /// Ascending breakpoints for Levels 1, 2, 3. Empty for binary.
    var thresholds: [Double]

    var schedule: HabitSchedule
    var reminderTime: Date?

    /// Soft-hide without deleting. Reference: app_concept.md §9.2.
    var isArchived: Bool
    var createdAt: Date

    /// Daily entries. Deleting a habit cascades to its logs.
    @Relationship(deleteRule: .cascade, inverse: \HabitLog.habit)
    var logs: [HabitLog]

    init(
        id: UUID = UUID(),
        ownerID: String = "",
        name: String,
        iconIdentifier: String = "flame.fill",
        colorHex: String = "48A69E",
        type: HabitType = .binary,
        unit: String? = nil,
        dailyTarget: Double = 1.0,
        overachieveTarget: Double = 1.0,
        thresholds: [Double] = [],
        schedule: HabitSchedule = .daily,
        reminderTime: Date? = nil,
        isArchived: Bool = false,
        createdAt: Date = .now,
        logs: [HabitLog] = []
    ) {
        self.id = id
        self.ownerID = ownerID
        self.name = name
        self.iconIdentifier = iconIdentifier
        self.colorHex = colorHex
        self.type = type
        self.unit = unit
        self.dailyTarget = dailyTarget
        self.overachieveTarget = overachieveTarget
        self.thresholds = thresholds
        self.schedule = schedule
        self.reminderTime = reminderTime
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.logs = logs
    }
}
