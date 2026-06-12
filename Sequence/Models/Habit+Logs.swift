//
//  Habit+Logs.swift
//  Sequence
//
//  Pure, persistence-free access to a habit's logged history. The engines
//  (Intensity / Streak / Stats) build on these helpers so their logic can be
//  unit-tested against in-memory habits without touching the repository.
//

import Foundation

extension Habit {

    /// The recorded value for a given day (0 if no entry). Day-normalized.
    func value(on date: Date, _ calendar: Calendar = .sequence) -> Double {
        let day = date.normalizedDay(calendar)
        return logs.first { $0.date == day }?.value ?? 0
    }

    /// Logs ordered oldest → newest by day.
    var sortedLogs: [HabitLog] {
        logs.sorted { $0.date < $1.date }
    }

    /// Every day (normalized) on which any activity was recorded (value > 0).
    var activeDates: Set<Date> {
        Set(logs.filter { $0.value > 0 }.map { $0.date })
    }

    /// Sum of all recorded values across history. Reference: app_concept.md §5.2.
    var totalVolume: Double {
        logs.reduce(0) { $0 + $1.value }
    }

    /// Frequency weight used by the momentum score. Reference: app_concept.md §5.1.
    /// Daily = 1.0; weekday sets scale by how many days/week; every-N-days = 1/N.
    var frequencyWeight: Double {
        switch schedule {
        case .daily:
            return 1.0
        case .weekdays(let days):
            return days.isEmpty ? 0 : Double(days.count) / 7.0
        case .everyNDays(let n):
            return n >= 1 ? 1.0 / Double(n) : 0
        }
    }
}
