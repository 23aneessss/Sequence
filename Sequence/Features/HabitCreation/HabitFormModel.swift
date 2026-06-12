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

    /// SF Symbols offered in the icon picker, grouped by habit category.
    static let iconChoices = [
        // Fitness & movement
        "figure.run", "figure.walk", "figure.hiking", "figure.yoga",
        "figure.strengthtraining.traditional", "figure.pool.swim", "dumbbell.fill",
        "bicycle", "sportscourt.fill", "soccerball",
        // Health & body
        "heart.fill", "pills.fill", "cross.case.fill", "lungs.fill",
        "bandage.fill", "stethoscope", "drop.fill", "eye.fill",
        // Mind & mindfulness
        "brain.head.profile", "sparkles", "leaf.fill", "moon.stars.fill", "lightbulb.fill",
        // Study & work
        "book.fill", "books.vertical.fill", "graduationcap.fill", "pencil",
        "laptopcomputer", "doc.text.fill", "function", "text.book.closed.fill",
        // Food & drink
        "cup.and.saucer.fill", "fork.knife", "carrot.fill",
        "takeoutbag.and.cup.and.straw.fill",
        // Sleep & time
        "bed.double.fill", "moon.fill", "sun.max.fill", "alarm.fill", "clock.fill",
        // Finance
        "dollarsign.circle.fill", "creditcard.fill", "banknote.fill",
        "chart.line.uptrend.xyaxis",
        // Creative
        "music.note", "paintbrush.fill", "camera.fill", "guitars.fill",
        "theatermasks.fill", "mic.fill", "paintpalette.fill",
        // Social
        "person.2.fill", "phone.fill", "envelope.fill", "bubble.left.fill", "hand.wave.fill",
        // Home & chores
        "house.fill", "cart.fill", "trash.fill", "hammer.fill", "basket.fill",
        // Motivation & misc
        "flame.fill", "star.fill", "trophy.fill", "flag.fill", "target",
        "checkmark.seal.fill", "globe", "gamecontroller.fill", "airplane", "pawprint.fill"
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
