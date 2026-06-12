//
//  RepositoryTests.swift
//  SequenceTests
//
//  Phase 2 acceptance: CRUD + logging correctness, the one-log-per-day
//  invariant, and persistence surviving container recreation ("relaunch").
//

import XCTest
import SwiftData
@testable import Sequence

final class RepositoryTests: XCTestCase {

    /// Temp store URLs created during a test, removed in `tearDown`.
    private var tempURLs: [URL] = []
    /// Containers must be retained for the test's lifetime — a `ModelContext`
    /// whose `ModelContainer` has deallocated will crash on use.
    private var retainedContainers: [ModelContainer] = []

    override func tearDownWithError() throws {
        retainedContainers.removeAll()
        for url in tempURLs {
            try? FileManager.default.removeItem(at: url)
        }
        tempURLs.removeAll()
    }

    // MARK: - Helpers

    /// An isolated repository backed by a unique on-disk temp store.
    ///
    /// We deliberately avoid `isStoredInMemoryOnly`: SwiftData crashes when an
    /// in-memory store is combined with `@Attribute(.unique)` constraints, which
    /// our models use. A throwaway file-backed store behaves exactly like
    /// production and is cleaned up in `tearDown`. The container is retained so
    /// the repository's context stays valid for the whole test.
    @MainActor
    private func makeRepo() throws -> SequenceRepository {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("seq-test-\(UUID().uuidString).store")
        tempURLs.append(url)
        let config = ModelConfiguration(schema: SequenceModelContainer.schema, url: url)
        let container = try ModelContainer(for: SequenceModelContainer.schema, configurations: [config])
        retainedContainers.append(container)
        return SequenceRepository(modelContext: container.mainContext)
    }

    // MARK: - Habit CRUD

    @MainActor
    func testCreateAndFetchHabit() throws {
        let repo = try makeRepo()
        XCTAssertTrue(repo.habits.isEmpty)

        repo.createHabit(name: "Meditate")
        XCTAssertEqual(repo.habits.count, 1)
        XCTAssertEqual(repo.habits.first?.name, "Meditate")
    }

    @MainActor
    func testArchiveRemovesFromActiveButKeepsData() throws {
        let repo = try makeRepo()
        let habit = repo.createHabit(name: "Read")

        repo.archiveHabit(habit)
        XCTAssertTrue(repo.habits.isEmpty)
        XCTAssertEqual(repo.allHabits(includeArchived: true).count, 1)

        repo.unarchiveHabit(habit)
        XCTAssertEqual(repo.habits.count, 1)
    }

    @MainActor
    func testDeleteHabitCascadesLogs() throws {
        let repo = try makeRepo()
        let habit = repo.createHabit(name: "Pushups", type: .counted, dailyTarget: 100)
        repo.setValue(50, for: habit, on: .now)
        XCTAssertEqual(habit.logs.count, 1)

        repo.deleteHabit(habit)
        XCTAssertTrue(repo.habits.isEmpty)
    }

    // MARK: - Logging invariants

    @MainActor
    func testIncrementAccumulatesIntoSingleDailyLog() throws {
        let repo = try makeRepo()
        let habit = repo.createHabit(name: "Water", type: .counted, dailyTarget: 8)

        repo.increment(habit, by: 1)
        repo.increment(habit, by: 1)
        repo.increment(habit, by: 3)

        XCTAssertEqual(habit.logs.count, 1, "Multiple logs in one day must collapse into one entry")
        XCTAssertEqual(repo.value(for: habit, on: .now), 5, accuracy: 0.001)
    }

    @MainActor
    func testSettingValueToZeroRemovesLog() throws {
        let repo = try makeRepo()
        let habit = repo.createHabit(name: "Vitamins")
        repo.setValue(1, for: habit, on: .now)
        XCTAssertEqual(habit.logs.count, 1)

        repo.setValue(0, for: habit, on: .now)
        XCTAssertEqual(habit.logs.count, 0)
    }

    @MainActor
    func testToggleBinary() throws {
        let repo = try makeRepo()
        let habit = repo.createHabit(name: "Make bed", type: .binary, dailyTarget: 1)

        XCTAssertTrue(repo.toggleBinary(habit))
        XCTAssertEqual(repo.value(for: habit, on: .now), 1, accuracy: 0.001)

        XCTAssertFalse(repo.toggleBinary(habit))
        XCTAssertEqual(repo.value(for: habit, on: .now), 0, accuracy: 0.001)
    }

    @MainActor
    func testDifferentDaysProduceDistinctLogs() throws {
        let repo = try makeRepo()
        let habit = repo.createHabit(name: "Run", type: .counted, dailyTarget: 5)
        let today = Date.now
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        repo.setValue(3, for: habit, on: today)
        repo.setValue(2, for: habit, on: yesterday)

        XCTAssertEqual(habit.logs.count, 2)
        XCTAssertEqual(repo.value(for: habit, on: today), 3, accuracy: 0.001)
        XCTAssertEqual(repo.value(for: habit, on: yesterday), 2, accuracy: 0.001)
    }

    // MARK: - Tasks

    @MainActor
    func testTasksSortedByPriorityThenTime() throws {
        let repo = try makeRepo()
        let day = Date.now
        repo.createTask(title: "Low", on: day, priority: .low)
        repo.createTask(title: "High", on: day, priority: .high)
        repo.createTask(title: "Medium", on: day, priority: .medium)

        let titles = repo.tasks(on: day).map(\.title)
        XCTAssertEqual(titles, ["High", "Medium", "Low"])
    }

    @MainActor
    func testToggleTaskStampsCompletion() throws {
        let repo = try makeRepo()
        let task = repo.createTask(title: "Ship it")
        XCTAssertFalse(task.isCompleted)
        XCTAssertNil(task.completedAt)

        repo.toggleTask(task)
        XCTAssertTrue(task.isCompleted)
        XCTAssertNotNil(task.completedAt)
    }

    @MainActor
    func testTemplatesExcludedFromDayBoard() throws {
        let repo = try makeRepo()
        let day = Date.now
        repo.createTask(title: "Normal", on: day)
        repo.createTask(title: "Template", on: day, isTemplate: true)

        XCTAssertEqual(repo.tasks(on: day).count, 1)
        XCTAssertEqual(repo.templateTasks().count, 1)
    }

    @MainActor
    func testTaskCompletionRates() throws {
        let repo = try makeRepo()
        let day = Date.now.normalizedDay()
        let a = repo.createTask(title: "A", on: day)
        repo.createTask(title: "B", on: day)
        repo.createTask(title: "C", on: day)
        repo.createTask(title: "D", on: day)
        repo.toggleTask(a) // 1 of 4 → 0.25

        let rates = repo.taskCompletionRates()
        XCTAssertEqual(rates[day] ?? -1, 0.25, accuracy: 0.001)
        XCTAssertEqual(repo.taskCompletion(on: day).total, 4)
        XCTAssertEqual(repo.taskCompletion(on: day).completed, 1)
    }

    @MainActor
    func testRollOverIncompleteTasks() throws {
        let repo = try makeRepo()
        let cal = Calendar.sequence
        let today = Date.now.normalizedDay()
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        let done = repo.createTask(title: "Done", on: yesterday)
        repo.toggleTask(done)
        repo.createTask(title: "Unfinished", on: yesterday)

        repo.rollOverIncompleteTasks(from: yesterday, to: today)

        let todayTitles = repo.tasks(on: today).map(\.title)
        XCTAssertEqual(todayTitles, ["Unfinished"], "Only incomplete tasks roll forward")
    }

    @MainActor
    func testTaskRevisionBumpsOnMutation() throws {
        let repo = try makeRepo()
        let before = repo.taskRevision
        let task = repo.createTask(title: "X")
        XCTAssertGreaterThan(repo.taskRevision, before)
        let afterCreate = repo.taskRevision
        repo.toggleTask(task)
        XCTAssertGreaterThan(repo.taskRevision, afterCreate)
    }

    // MARK: - Persistence across "relaunch"

    /// Writes through one container, releases it, opens a fresh container at the
    /// same on-disk URL, and confirms the data is still there — simulating an
    /// app relaunch.
    @MainActor
    func testPersistenceSurvivesContainerRecreation() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("seq-test-\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: url) }

        let habitID: UUID

        // First "launch": write a habit + a log, then save.
        do {
            let config = ModelConfiguration(schema: SequenceModelContainer.schema, url: url)
            let container = try ModelContainer(for: SequenceModelContainer.schema, configurations: [config])
            let repo = SequenceRepository(modelContext: container.mainContext)
            let habit = repo.createHabit(name: "Journal", type: .counted, dailyTarget: 500)
            habitID = habit.id
            repo.setValue(250, for: habit, on: .now)
        }

        // Second "launch": fresh container at the same URL must see the data.
        let config = ModelConfiguration(schema: SequenceModelContainer.schema, url: url)
        let container = try ModelContainer(for: SequenceModelContainer.schema, configurations: [config])
        let repo = SequenceRepository(modelContext: container.mainContext)

        XCTAssertEqual(repo.habits.count, 1)
        let reloaded = try XCTUnwrap(repo.habits.first { $0.id == habitID })
        XCTAssertEqual(reloaded.name, "Journal")
        XCTAssertEqual(repo.value(for: reloaded, on: .now), 250, accuracy: 0.001)
    }
}
