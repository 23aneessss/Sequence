//
//  DemoSeeder.swift
//  Sequence
//
//  Development-only seeding, gated behind the SEQ_SEED environment variable so
//  normal launches stay clean. Used to populate the live store with realistic
//  habits + history for screenshot verification:
//
//      SIMCTL_CHILD_SEQ_SEED=1 xcrun simctl launch <dev> com.sequence.app
//
//  Re-runs are idempotent: it no-ops if any habit already exists.
//

import Foundation

enum DemoSeeder {

    static func seedIfRequested(into repo: SequenceRepository) {
        guard ProcessInfo.processInfo.environment["SEQ_SEED"] == "1" else { return }
        guard repo.habits.isEmpty else { return }

        let calendar = Calendar.sequence
        let today = Date.now.normalizedDay(calendar)
        var rng = SeededGenerator(seed: 42)

        // Binary — a strong recent streak.
        let meditate = repo.createHabit(name: "Meditate", iconIdentifier: "brain.head.profile",
                                        colorHex: "8E6FD8", type: .binary, dailyTarget: 1)
        meditate.createdAt = calendar.date(byAdding: .day, value: -120, to: today) ?? today
        for offset in 0..<120 where offset == 0 || rng.chance(78) {
            repo.setValue(1, for: meditate, on: calendar.date(byAdding: .day, value: -offset, to: today)!)
        }

        // Counted — pushups with varied volume.
        let pushups = repo.createHabit(name: "Pushups", iconIdentifier: "figure.strengthtraining.traditional",
                                       colorHex: "48A69E", type: .counted, unit: "reps",
                                       dailyTarget: 100, overachieveTarget: 150, thresholds: [25, 50, 75])
        pushups.createdAt = calendar.date(byAdding: .day, value: -200, to: today) ?? today
        for offset in 0..<200 where rng.chance(68) {
            let value = Double(rng.int(in: 10...160))
            repo.setValue(value, for: pushups, on: calendar.date(byAdding: .day, value: -offset, to: today)!)
        }

        // Timed — deep work in minutes, with a broken streak (skips today + yesterday).
        let deepWork = repo.createHabit(name: "Deep Work", iconIdentifier: "laptopcomputer",
                                        colorHex: "E6A817", type: .timed, unit: "min",
                                        dailyTarget: 90, overachieveTarget: 150, thresholds: [30, 50, 70])
        deepWork.createdAt = calendar.date(byAdding: .day, value: -150, to: today) ?? today
        for offset in 2..<150 where rng.chance(60) {
            let value = Double(rng.int(in: 20...160))
            repo.setValue(value, for: deepWork, on: calendar.date(byAdding: .day, value: -offset, to: today)!)
        }

        seedTasks(into: repo, calendar: calendar, today: today, rng: &rng)
        repo.refresh()
    }

    private static func seedTasks(into repo: SequenceRepository, calendar: Calendar,
                                  today: Date, rng: inout SeededGenerator) {
        let titles = ["Inbox zero", "Workout", "Read 20 pages", "Plan tomorrow", "Call family"]
        // Historical days with varied completion rates → varied graph intensity.
        for offset in 1..<120 where rng.chance(55) {
            let date = calendar.date(byAdding: .day, value: -offset, to: today)!
            let count = rng.int(in: 2...4)
            let completeUpTo = rng.int(in: 0...count) // some days perfect, some partial
            for i in 0..<count {
                let task = repo.createTask(title: titles[i % titles.count], on: date)
                if i < completeUpTo { repo.toggleTask(task) }
            }
        }
        // Today's board: a few tasks, one already done.
        let t1 = repo.createTask(title: "Inbox zero", on: today, priority: .high)
        repo.toggleTask(t1)
        repo.createTask(title: "Workout", on: today, priority: .medium,
                        timeAnchor: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: today))
        repo.createTask(title: "Read 20 pages", on: today, priority: .low)
        // A template suggestion.
        repo.createTask(title: "Journal", on: today, isTemplate: true)
    }
}

/// A tiny deterministic PRNG so seeded data is identical run-to-run.
private struct SeededGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed &* 2862933555777941757 &+ 3037000493 }

    private mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
    mutating func int(in range: ClosedRange<Int>) -> Int {
        let span = UInt64(range.upperBound - range.lowerBound + 1)
        return range.lowerBound + Int(next() % span)
    }
    mutating func chance(_ percent: Int) -> Bool { int(in: 1...100) <= percent }
}
