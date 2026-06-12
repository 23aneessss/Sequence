//
//  EngineTests.swift
//  SequenceTests
//
//  Phase 3 acceptance: exhaustive boundary coverage for the four engines.
//  The contribution graph and every stat the user sees rest on this logic.
//

import XCTest
import SwiftUI
import SwiftData
@testable import Sequence

final class EngineTests: XCTestCase {

    // MARK: - Fixtures

    private var retainedContainers: [ModelContainer] = []
    private var tempURLs: [URL] = []

    override func tearDownWithError() throws {
        retainedContainers.removeAll()
        for url in tempURLs { try? FileManager.default.removeItem(at: url) }
        tempURLs.removeAll()
    }

    /// Repository backed by a retained, file-backed temp store (see RepositoryTests
    /// for why in-memory + retain matters).
    @MainActor
    private func makeRepo() throws -> SequenceRepository {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("seq-eng-\(UUID().uuidString).store")
        tempURLs.append(url)
        let config = ModelConfiguration(schema: SequenceModelContainer.schema, url: url)
        let container = try ModelContainer(for: SequenceModelContainer.schema, configurations: [config])
        retainedContainers.append(container)
        return SequenceRepository(modelContext: container.mainContext)
    }

    private let cal = Calendar.sequence
    /// A normalized day `offset` days from a fixed base (default: today).
    private func day(_ offset: Int, from base: Date = .now) -> Date {
        cal.date(byAdding: .day, value: offset, to: base.normalizedDay(cal))!
    }

    // MARK: - IntensityEngine: counted habit at every boundary

    func testCountedIntensityBoundaries() {
        let engine = IntensityEngine()
        // dailyTarget 100, overachieve 150, explicit thresholds [25, 50, 75].
        let habit = Habit(name: "Pushups", type: .counted,
                          dailyTarget: 100, overachieveTarget: 150, thresholds: [25, 50, 75])

        let cases: [(Double, IntensityLevel)] = [
            (0, .empty), (1, .minimal), (24, .minimal), (25, .minimal), (49, .minimal),
            (50, .low), (74, .low),
            (75, .medium), (99, .medium),
            (100, .full), (149, .full),
            (150, .overachieved), (300, .overachieved)
        ]
        for (value, expected) in cases {
            XCTAssertEqual(engine.level(value: value, for: habit), expected,
                           "value \(value) should map to \(expected)")
        }
    }

    func testBinaryIntensityUsesOnlyEmptyAndFull() {
        let engine = IntensityEngine()
        let habit = Habit(name: "Make bed", type: .binary, dailyTarget: 1)
        XCTAssertEqual(engine.level(value: 0, for: habit), .empty)
        XCTAssertEqual(engine.level(value: 0.5, for: habit), .empty)
        XCTAssertEqual(engine.level(value: 1, for: habit), .full)
        XCTAssertEqual(engine.level(value: 5, for: habit), .full)
    }

    func testCountedWithoutDistinctOverachieveCapsAtFull() {
        let engine = IntensityEngine()
        let habit = Habit(name: "Water", type: .counted, dailyTarget: 8, overachieveTarget: 8)
        XCTAssertEqual(engine.level(value: 8, for: habit), .full)
        XCTAssertEqual(engine.level(value: 100, for: habit), .full, "No overachieve target → never level 5")
    }

    func testDefaultThresholdsDeriveFromDailyTarget() {
        let engine = IntensityEngine()
        // No thresholds supplied → 25/50/75% of 100.
        let habit = Habit(name: "Read", type: .counted, dailyTarget: 100, overachieveTarget: 120)
        XCTAssertEqual(engine.effectiveThresholds(for: habit), [25, 50, 75])
        XCTAssertEqual(engine.level(value: 60, for: habit), .low)
        XCTAssertEqual(engine.level(value: 80, for: habit), .medium)
    }

    // MARK: - IntensityEngine: task completion rate

    func testTaskCompletionRateBoundaries() {
        let engine = IntensityEngine()
        XCTAssertEqual(engine.taskLevel(completionRate: 0.0), .empty)
        XCTAssertEqual(engine.taskLevel(completionRate: 0.10), .minimal)
        XCTAssertEqual(engine.taskLevel(completionRate: 0.24), .minimal)
        XCTAssertEqual(engine.taskLevel(completionRate: 0.25), .low)
        XCTAssertEqual(engine.taskLevel(completionRate: 0.49), .low)
        XCTAssertEqual(engine.taskLevel(completionRate: 0.50), .medium)
        XCTAssertEqual(engine.taskLevel(completionRate: 0.74), .medium)
        XCTAssertEqual(engine.taskLevel(completionRate: 0.75), .full)
        XCTAssertEqual(engine.taskLevel(completionRate: 0.99), .full)
        XCTAssertEqual(engine.taskLevel(completionRate: 1.0), .overachieved)
    }

    func testTaskLevelFromCounts() {
        let engine = IntensityEngine()
        XCTAssertEqual(engine.taskLevel(completed: 0, total: 0), .empty)
        XCTAssertEqual(engine.taskLevel(completed: 3, total: 4), .full)
        XCTAssertEqual(engine.taskLevel(completed: 4, total: 4), .overachieved)
    }

    // MARK: - StreakEngine: pure set-based

    func testCurrentStreakAnchoredToday() {
        let engine = StreakEngine()
        let days: Set<Date> = [day(0), day(-1), day(-2)]
        XCTAssertEqual(engine.currentStreak(days: days), 3)
    }

    func testCurrentStreakSurvivesUnloggedToday() {
        let engine = StreakEngine()
        // Today not logged, but yesterday back three days are — streak not yet broken.
        let days: Set<Date> = [day(-1), day(-2), day(-3)]
        XCTAssertEqual(engine.currentStreak(days: days), 3)
    }

    func testCurrentStreakBreaksAfterMissedDay() {
        let engine = StreakEngine()
        // Gap at yesterday and today → streak is dead.
        let days: Set<Date> = [day(-2), day(-3)]
        XCTAssertEqual(engine.currentStreak(days: days), 0)
    }

    func testBestStreakAcrossGaps() {
        let engine = StreakEngine()
        let days: Set<Date> = [day(-10), day(-9), day(-8), // run of 3
                               day(-5), day(-4),           // run of 2
                               day(0)]                     // run of 1
        XCTAssertEqual(engine.bestStreak(days: days), 3)
    }

    func testEmptyStreaks() {
        let engine = StreakEngine()
        XCTAssertEqual(engine.currentStreak(days: []), 0)
        XCTAssertEqual(engine.bestStreak(days: []), 0)
    }

    @MainActor
    func testStreakRespectsMinLevelThreshold() throws {
        let repo = try makeRepo()
        // Counted, target 100. Day -0 partial (level minimal), day -1 full.
        let habit = repo.createHabit(name: "Run", type: .counted, dailyTarget: 100,
                                     overachieveTarget: 150, thresholds: [25, 50, 75])
        repo.setValue(10, for: habit, on: day(0))    // minimal
        repo.setValue(100, for: habit, on: day(-1))  // full

        // Default minLevel = .minimal → both days count.
        XCTAssertEqual(StreakEngine().currentStreak(for: habit, asOf: day(0)), 2)

        // Raise threshold to .full → only day -1 qualifies, today doesn't,
        // so the streak (ending yesterday) is 1.
        var strict = StreakEngine(); strict.minLevel = .full
        XCTAssertEqual(strict.currentStreak(for: habit, asOf: day(0)), 1)
    }

    // MARK: - StatsEngine

    @MainActor
    func testPerHabitStatistics() throws {
        let repo = try makeRepo()
        let habit = repo.createHabit(name: "Pushups", type: .counted, dailyTarget: 100,
                                     overachieveTarget: 150, thresholds: [25, 50, 75])
        // Force an old creation date so the all-time window is meaningful.
        habit.createdAt = day(-9)
        repo.setValue(100, for: habit, on: day(0))   // full
        repo.setValue(120, for: habit, on: day(-1))  // full
        repo.setValue(40, for: habit, on: day(-2))   // low (not "completed")

        let stats = StatsEngine().statistics(for: habit, asOf: day(0))
        XCTAssertEqual(stats.currentStreak, 3)
        XCTAssertEqual(stats.bestStreak, 3)
        XCTAssertEqual(stats.totalActiveDays, 3)
        XCTAssertEqual(stats.bestDayEver, 120, accuracy: 0.001)
        XCTAssertEqual(stats.totalLifetimeVolume, 260, accuracy: 0.001)
        XCTAssertEqual(stats.averageDailyCount, 260.0 / 3.0, accuracy: 0.001)
        // 2 of 3 days reached full over a 30-day window bounded to 10 days of history.
        XCTAssertEqual(stats.completionRate30d, 2.0 / 10.0 * 100, accuracy: 0.001)
    }

    @MainActor
    func testTrendDirection() throws {
        let repo = try makeRepo()
        let habit = repo.createHabit(name: "Write", type: .counted, dailyTarget: 500)
        habit.createdAt = day(-40)
        // Recent 14 days: lots of volume. Prior 14 days: little.
        repo.setValue(500, for: habit, on: day(-1))
        repo.setValue(500, for: habit, on: day(-2))
        repo.setValue(50, for: habit, on: day(-20))
        XCTAssertEqual(StatsEngine().trend(for: habit, asOf: day(0)), .up)

        // Flat when both windows are empty.
        let fresh = repo.createHabit(name: "Idle", type: .counted, dailyTarget: 10)
        XCTAssertEqual(StatsEngine().trend(for: fresh, asOf: day(0)), .flat)
    }

    @MainActor
    func testMomentumScoreWeightsByFrequency() throws {
        let repo = try makeRepo()
        let daily = repo.createHabit(name: "A", type: .binary, dailyTarget: 1, schedule: .daily)
        let everyOther = repo.createHabit(name: "B", type: .binary, dailyTarget: 1,
                                          schedule: .everyNDays(2))
        // Daily habit: 3-day streak. Every-other habit: streak of 1 today.
        repo.setValue(1, for: daily, on: day(0))
        repo.setValue(1, for: daily, on: day(-1))
        repo.setValue(1, for: daily, on: day(-2))
        repo.setValue(1, for: everyOther, on: day(0))

        // weighted = (3 * 1.0 + 1 * 0.5) / (1.0 + 0.5) = 3.5 / 1.5
        let score = StatsEngine().momentumScore(habits: repo.habits, asOf: day(0))
        XCTAssertEqual(score, 3.5 / 1.5, accuracy: 0.001)
    }

    @MainActor
    func testSeriousnessIndex() throws {
        let repo = try makeRepo()
        let a = repo.createHabit(name: "A", type: .binary, dailyTarget: 1)
        let b = repo.createHabit(name: "B", type: .binary, dailyTarget: 1)
        // 3 distinct active days within the last 90 (overlap on day 0 counts once).
        repo.setValue(1, for: a, on: day(0))
        repo.setValue(1, for: b, on: day(0))
        repo.setValue(1, for: a, on: day(-5))
        repo.setValue(1, for: b, on: day(-40))

        let index = StatsEngine().seriousnessIndex(habits: repo.habits, lookbackDays: 90, asOf: day(0))
        XCTAssertEqual(index, 3.0 / 90.0 * 100, accuracy: 0.001)
    }

    // MARK: - ColorScaleEngine

    private func hsb(of color: Color) -> (h: CGFloat, s: CGFloat, b: CGFloat) {
        var h: CGFloat = 0, s: CGFloat = 0, br: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getHue(&h, saturation: &s, brightness: &br, alpha: &a)
        return (h, s, br)
    }

    func testScaleHasSixLevels() {
        XCTAssertEqual(ColorScaleEngine.scale(forHex: "48A69E").count, 6)
    }

    func testSaturationIncreasesWithLevel() {
        let hex = "48A69E"
        let s1 = hsb(of: ColorScaleEngine.color(forHex: hex, level: .minimal)).s
        let s2 = hsb(of: ColorScaleEngine.color(forHex: hex, level: .low)).s
        let s3 = hsb(of: ColorScaleEngine.color(forHex: hex, level: .medium)).s
        let s4 = hsb(of: ColorScaleEngine.color(forHex: hex, level: .full)).s
        XCTAssertLessThan(s1, s2)
        XCTAssertLessThan(s2, s3)
        XCTAssertLessThan(s3, s4)
    }

    func testOverachievedIsDarkerThanFull() {
        let hex = "48A69E"
        let bFull = hsb(of: ColorScaleEngine.color(forHex: hex, level: .full)).b
        let bOver = hsb(of: ColorScaleEngine.color(forHex: hex, level: .overachieved)).b
        XCTAssertLessThan(bOver, bFull)
    }

    func testHuePreservedAcrossLevels() {
        let baseHue = hsb(of: Color(hex: "E05C5C")).h
        for level in [IntensityLevel.minimal, .low, .medium, .full, .overachieved] {
            let h = hsb(of: ColorScaleEngine.color(forHex: "E05C5C", level: level)).h
            XCTAssertEqual(h, baseHue, accuracy: 0.02, "hue drifted at level \(level)")
        }
    }
}
