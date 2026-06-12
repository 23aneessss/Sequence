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

    // MARK: - Helpers

    /// An in-memory repository for fast, isolated CRUD tests.
    @MainActor
    private func makeInMemoryRepo() throws -> SequenceRepository {
        let container = try SequenceModelContainer.inMemory()
        return SequenceRepository(modelContext: container.mainContext)
    }

    // MARK: - Habit CRUD

    @MainActor
    func testCreateAndFetchHabit() throws {
        let repo = try makeInMemoryRepo()
        XCTAssertTrue(repo.habits.isEmpty)

        repo.createHabit(name: "Meditate")
        XCTAssertEqual(repo.habits.count, 1)
        XCTAssertEqual(repo.habits.first?.name, "Meditate")
    }

    @MainActor
    func testArchiveRemovesFromActiveButKeepsData() throws {
        let repo = try makeInMemoryRepo()
        let habit = repo.createHabit(name: "Read")

        repo.archiveHabit(habit)
        XCTAssertTrue(repo.habits.isEmpty)
        XCTAssertEqual(repo.allHabits(includeArchived: true).count, 1)

        repo.unarchiveHabit(habit)
        XCTAssertEqual(repo.habits.count, 1)
    }

    @MainActor
    func testDeleteHabitCascadesLogs() throws {
        let repo = try makeInMemoryRepo()
        let habit = repo.createHabit(name: "Pushups", type: .counted, dailyTarget: 100)
        repo.setValue(50, for: habit, on: .now)
        XCTAssertEqual(habit.logs.count, 1)

        repo.deleteHabit(habit)
        XCTAssertTrue(repo.habits.isEmpty)
    }

    // MARK: - Logging invariants

    @MainActor
    func testIncrementAccumulatesIntoSingleDailyLog() throws {
        let repo = try makeInMemoryRepo()
        let habit = repo.createHabit(name: "Water", type: .counted, dailyTarget: 8)

        repo.increment(habit, by: 1)
        repo.increment(habit, by: 1)
        repo.increment(habit, by: 3)

        XCTAssertEqual(habit.logs.count, 1, "Multiple logs in one day must collapse into one entry")
        XCTAssertEqual(repo.value(for: habit, on: .now), 5, accuracy: 0.001)
    }

    @MainActor
    func testSettingValueToZeroRemovesLog() throws {
        let repo = try makeInMemoryRepo()
        let habit = repo.createHabit(name: "Vitamins")
        repo.setValue(1, for: habit, on: .now)
        XCTAssertEqual(habit.logs.count, 1)

        repo.setValue(0, for: habit, on: .now)
        XCTAssertEqual(habit.logs.count, 0)
    }

    @MainActor
    func testToggleBinary() throws {
        let repo = try makeInMemoryRepo()
        let habit = repo.createHabit(name: "Make bed", type: .binary, dailyTarget: 1)

        XCTAssertTrue(repo.toggleBinary(habit))
        XCTAssertEqual(repo.value(for: habit, on: .now), 1, accuracy: 0.001)

        XCTAssertFalse(repo.toggleBinary(habit))
        XCTAssertEqual(repo.value(for: habit, on: .now), 0, accuracy: 0.001)
    }

    @MainActor
    func testDifferentDaysProduceDistinctLogs() throws {
        let repo = try makeInMemoryRepo()
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
        let repo = try makeInMemoryRepo()
        let day = Date.now
        repo.createTask(title: "Low", on: day, priority: .low)
        repo.createTask(title: "High", on: day, priority: .high)
        repo.createTask(title: "Medium", on: day, priority: .medium)

        let titles = repo.tasks(on: day).map(\.title)
        XCTAssertEqual(titles, ["High", "Medium", "Low"])
    }

    @MainActor
    func testToggleTaskStampsCompletion() throws {
        let repo = try makeInMemoryRepo()
        let task = repo.createTask(title: "Ship it")
        XCTAssertFalse(task.isCompleted)
        XCTAssertNil(task.completedAt)

        repo.toggleTask(task)
        XCTAssertTrue(task.isCompleted)
        XCTAssertNotNil(task.completedAt)
    }

    @MainActor
    func testTemplatesExcludedFromDayBoard() throws {
        let repo = try makeInMemoryRepo()
        let day = Date.now
        repo.createTask(title: "Normal", on: day)
        repo.createTask(title: "Template", on: day, isTemplate: true)

        XCTAssertEqual(repo.tasks(on: day).count, 1)
        XCTAssertEqual(repo.templateTasks().count, 1)
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
