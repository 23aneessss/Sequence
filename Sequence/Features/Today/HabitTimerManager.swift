//
//  HabitTimerManager.swift
//  Sequence
//
//  Tracks running timers for timed habits. Reference: app_concept.md §3.1 (Type C).
//
//  Per our Phase decision, duration is computed by timestamp difference rather
//  than a true background-running clock: we persist each habit's start time in
//  UserDefaults, so a timer survives backgrounding/relaunch and resolves to the
//  correct elapsed minutes when stopped.
//

import Foundation
import Observation

@Observable
final class HabitTimerManager {

    /// habitID → start date for currently-running timers.
    private(set) var startTimes: [UUID: Date] = [:]

    private let storeKey = "sequence.runningTimers"

    init() {
        if let raw = UserDefaults.standard.dictionary(forKey: storeKey) as? [String: Double] {
            for (key, ts) in raw {
                if let id = UUID(uuidString: key) {
                    startTimes[id] = Date(timeIntervalSince1970: ts)
                }
            }
        }
    }

    func isRunning(_ habit: Habit) -> Bool {
        startTimes[habit.id] != nil
    }

    /// Elapsed seconds for a running timer (0 if not running).
    func elapsedSeconds(_ habit: Habit, now: Date = .now) -> TimeInterval {
        guard let start = startTimes[habit.id] else { return 0 }
        return max(0, now.timeIntervalSince(start))
    }

    func start(_ habit: Habit) {
        startTimes[habit.id] = .now
        persist()
    }

    /// Stops the timer and returns elapsed whole minutes (rounded), or nil if not running.
    @discardableResult
    func stop(_ habit: Habit, now: Date = .now) -> Double? {
        guard let start = startTimes[habit.id] else { return nil }
        startTimes[habit.id] = nil
        persist()
        let minutes = now.timeIntervalSince(start) / 60.0
        return (minutes * 10).rounded() / 10 // 0.1-minute precision
    }

    private func persist() {
        let raw = startTimes.reduce(into: [String: Double]()) { dict, pair in
            dict[pair.key.uuidString] = pair.value.timeIntervalSince1970
        }
        UserDefaults.standard.set(raw, forKey: storeKey)
    }
}
