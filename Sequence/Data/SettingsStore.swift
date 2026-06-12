//
//  SettingsStore.swift
//  Sequence
//
//  App-wide preferences, persisted to UserDefaults. Reference: app_concept.md §9.4.
//

import SwiftUI
import Observation

/// Appearance override. Reference: app_concept.md §9.4 (Light / Dark / System).
enum AppAppearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

/// Graph reading direction. Reference: app_concept.md §9.4.
enum GraphDirection: String, CaseIterable, Identifiable {
    case recentRight, recentLeft
    var id: String { rawValue }
    var displayName: String { self == .recentRight ? "Recent → right" : "Recent → left" }
}

@Observable
final class SettingsStore {

    private enum Keys {
        static let appearance = "sequence.appearance"
        static let weekStart = "sequence.weekStartsOn"
        static let graphDirection = "sequence.graphDirection"
        static let streakMinLevel = "sequence.streakMinLevel"
        static let reminderTime = "sequence.defaultReminderTime"
        static let taskReminderTime = "sequence.taskReminderTime"
        static let dndEnabled = "sequence.dndEnabled"
        static let dndStart = "sequence.dndStart"
        static let dndEnd = "sequence.dndEnd"
    }

    private let defaults = UserDefaults.standard

    var appearance: AppAppearance {
        didSet { defaults.set(appearance.rawValue, forKey: Keys.appearance) }
    }
    /// 1 = Sunday, 2 = Monday.
    var weekStartsOn: Int {
        didSet { defaults.set(weekStartsOn, forKey: Keys.weekStart) }
    }
    var graphDirection: GraphDirection {
        didSet { defaults.set(graphDirection.rawValue, forKey: Keys.graphDirection) }
    }
    /// Minimum intensity (1…5) that counts as a streak day. Reference: app_concept.md §9.4.
    var streakMinLevel: Int {
        didSet { defaults.set(streakMinLevel, forKey: Keys.streakMinLevel) }
    }
    var defaultReminderTime: Date {
        didSet { defaults.set(defaultReminderTime.timeIntervalSince1970, forKey: Keys.reminderTime) }
    }
    /// Morning task-board summary time. Reference: app_concept.md §6.1 (Type 3, default 08:00).
    var taskReminderTime: Date {
        didSet { defaults.set(taskReminderTime.timeIntervalSince1970, forKey: Keys.taskReminderTime) }
    }
    /// Do-Not-Disturb window for streak-at-risk alerts. Reference: app_concept.md §6.1.
    var dndEnabled: Bool {
        didSet { defaults.set(dndEnabled, forKey: Keys.dndEnabled) }
    }
    var dndStart: Date {
        didSet { defaults.set(dndStart.timeIntervalSince1970, forKey: Keys.dndStart) }
    }
    var dndEnd: Date {
        didSet { defaults.set(dndEnd.timeIntervalSince1970, forKey: Keys.dndEnd) }
    }

    init() {
        appearance = AppAppearance(rawValue: defaults.string(forKey: Keys.appearance) ?? "") ?? .system
        let storedWeek = defaults.integer(forKey: Keys.weekStart)
        weekStartsOn = storedWeek == 0 ? 1 : storedWeek
        graphDirection = GraphDirection(rawValue: defaults.string(forKey: Keys.graphDirection) ?? "") ?? .recentRight
        let storedLevel = defaults.integer(forKey: Keys.streakMinLevel)
        streakMinLevel = storedLevel == 0 ? 1 : storedLevel
        let storedReminder = defaults.double(forKey: Keys.reminderTime)
        defaultReminderTime = storedReminder == 0
            ? (Calendar.sequence.date(bySettingHour: 9, minute: 0, second: 0, of: .now) ?? .now)
            : Date(timeIntervalSince1970: storedReminder)

        let cal = Calendar.sequence
        let storedTask = defaults.double(forKey: Keys.taskReminderTime)
        taskReminderTime = storedTask == 0
            ? (cal.date(bySettingHour: 8, minute: 0, second: 0, of: .now) ?? .now)
            : Date(timeIntervalSince1970: storedTask)
        dndEnabled = defaults.object(forKey: Keys.dndEnabled) as? Bool ?? true
        let storedDndStart = defaults.double(forKey: Keys.dndStart)
        dndStart = storedDndStart == 0
            ? (cal.date(bySettingHour: 22, minute: 0, second: 0, of: .now) ?? .now)
            : Date(timeIntervalSince1970: storedDndStart)
        let storedDndEnd = defaults.double(forKey: Keys.dndEnd)
        dndEnd = storedDndEnd == 0
            ? (cal.date(bySettingHour: 7, minute: 0, second: 0, of: .now) ?? .now)
            : Date(timeIntervalSince1970: storedDndEnd)
    }

    /// A streak engine configured with the user's threshold + week start.
    func makeStreakEngine() -> StreakEngine {
        var engine = StreakEngine()
        engine.minLevel = IntensityLevel(rawValue: streakMinLevel) ?? .minimal
        return engine
    }

    /// Whether a given clock time falls inside the DND window (handles overnight spans).
    func isInDoNotDisturb(_ date: Date, _ calendar: Calendar = .sequence) -> Bool {
        guard dndEnabled else { return false }
        let minutes = { (d: Date) -> Int in
            let c = calendar.dateComponents([.hour, .minute], from: d)
            return (c.hour ?? 0) * 60 + (c.minute ?? 0)
        }
        let now = minutes(date), start = minutes(dndStart), end = minutes(dndEnd)
        return start <= end ? (now >= start && now < end) : (now >= start || now < end)
    }
}
