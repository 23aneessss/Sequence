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
    }

    /// A streak engine configured with the user's threshold + week start.
    func makeStreakEngine() -> StreakEngine {
        var engine = StreakEngine()
        engine.minLevel = IntensityLevel(rawValue: streakMinLevel) ?? .minimal
        return engine
    }
}
