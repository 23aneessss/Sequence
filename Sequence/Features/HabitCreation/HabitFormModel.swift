//
//  HabitFormModel.swift
//  Sequence
//
//  Mutable state for the habit creation flow. Reference: app_concept.md §3.3.
//

import SwiftUI
import Observation

@Observable
final class HabitFormModel {
    var name = ""
    var icon = "flame.fill"
    var colorHex = DefaultPalette.defaultHex
    var type: HabitType = .binary
    var unit = ""
    var dailyTarget = 1.0
    var overachieveTarget = 1.0

    // Schedule
    enum ScheduleKind: String, CaseIterable, Identifiable { case daily, weekdays, everyN; var id: String { rawValue } }
    var scheduleKind: ScheduleKind = .daily
    var selectedWeekdays: Set<Int> = [2, 3, 4, 5, 6] // Mon–Fri default
    var everyNDays = 2

    // Reminder
    var reminderOn = false
    var reminderTime = Calendar.sequence.date(bySettingHour: 9, minute: 0, second: 0, of: .now) ?? .now

    /// Common SF Symbols offered in the icon picker.
    static let iconChoices = [
        "flame.fill", "drop.fill", "book.fill", "dumbbell.fill",
        "figure.run", "brain.head.profile", "laptopcomputer", "leaf.fill",
        "bed.double.fill", "pencil", "music.note", "heart.fill",
        "cup.and.saucer.fill", "moon.fill", "sun.max.fill", "pills.fill"
    ]

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        (type == .binary || dailyTarget > 0)
    }

    /// Effective targets, normalizing binary habits to 1.0.
    private var resolvedTargets: (daily: Double, over: Double) {
        guard type != .binary else { return (1.0, 1.0) }
        return (dailyTarget, max(overachieveTarget, dailyTarget))
    }

    var schedule: HabitSchedule {
        switch scheduleKind {
        case .daily:    return .daily
        case .weekdays: return .on(selectedWeekdays)
        case .everyN:   return .everyNDays(max(1, everyNDays))
        }
    }

    /// Persists the configured habit through the repository.
    @discardableResult
    func create(using repo: SequenceRepository) -> Habit {
        let targets = resolvedTargets
        return repo.createHabit(
            name: name.trimmingCharacters(in: .whitespaces),
            iconIdentifier: icon,
            colorHex: colorHex,
            type: type,
            unit: type == .binary ? nil : (unit.isEmpty ? nil : unit),
            dailyTarget: targets.daily,
            overachieveTarget: targets.over,
            thresholds: [], // engine derives sensible 25/50/75% gates
            schedule: schedule,
            reminderTime: reminderOn ? reminderTime : nil
        )
    }
}
