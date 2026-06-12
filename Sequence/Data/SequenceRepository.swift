//
//  SequenceRepository.swift
//  Sequence
//
//  The data + aggregation layer. Reference: product_design.md §7.3.
//  No raw model mutation happens in views — all writes route through here so
//  day-bucketing and the one-log-per-day invariant stay enforced.
//
//  This phase covers persistence (CRUD + logging). Intensity/streak/stats
//  computation arrives in Phase 3 as separate engines that read this data.
//

import Foundation
import SwiftData
import Observation

@Observable
final class SequenceRepository {

    private let modelContext: ModelContext

    /// Active (non-archived) habits, oldest first. Refreshed on mutation.
    private(set) var habits: [Habit] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        refresh()
    }

    // MARK: - Fetching

    /// Reloads `habits` from the store (non-archived, oldest first).
    func refresh() {
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        do {
            habits = try modelContext.fetch(descriptor)
        } catch {
            print("SequenceRepository: failed to fetch habits — \(error)")
            habits = []
        }
    }

    /// All habits including archived ones, oldest first.
    func allHabits(includeArchived: Bool) -> [Habit] {
        let descriptor = FetchDescriptor<Habit>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        let all = (try? modelContext.fetch(descriptor)) ?? []
        return includeArchived ? all : all.filter { !$0.isArchived }
    }

    // MARK: - Habit CRUD

    @discardableResult
    func createHabit(
        name: String,
        iconIdentifier: String = "flame.fill",
        colorHex: String = "48A69E",
        type: HabitType = .binary,
        unit: String? = nil,
        dailyTarget: Double = 1.0,
        overachieveTarget: Double = 1.0,
        thresholds: [Double] = [],
        schedule: HabitSchedule = .daily,
        reminderTime: Date? = nil
    ) -> Habit {
        let habit = Habit(
            name: name,
            iconIdentifier: iconIdentifier,
            colorHex: colorHex,
            type: type,
            unit: unit,
            dailyTarget: dailyTarget,
            overachieveTarget: overachieveTarget,
            thresholds: thresholds,
            schedule: schedule,
            reminderTime: reminderTime
        )
        modelContext.insert(habit)
        save()
        refresh()
        return habit
    }

    /// Persists in-place edits to a habit's properties.
    func updateHabit(_ habit: Habit) {
        save()
        refresh()
    }

    /// Soft-hide: keeps data, removes from active lists.
    func archiveHabit(_ habit: Habit) {
        habit.isArchived = true
        save()
        refresh()
    }

    func unarchiveHabit(_ habit: Habit) {
        habit.isArchived = false
        save()
        refresh()
    }

    /// Hard delete — cascades to the habit's logs.
    func deleteHabit(_ habit: Habit) {
        modelContext.delete(habit)
        save()
        refresh()
    }

    // MARK: - Logging (one entry per habit per normalized day)

    /// The habit's log for the given day, if any.
    func dayLog(for habit: Habit, on date: Date) -> HabitLog? {
        let day = date.normalizedDay()
        return habit.logs.first { $0.date == day }
    }

    /// The recorded value for a habit on a day (0 if no entry).
    func value(for habit: Habit, on date: Date) -> Double {
        dayLog(for: habit, on: date)?.value ?? 0
    }

    /// Sets the absolute value for a day. A value of 0 removes the entry.
    @discardableResult
    func setValue(_ value: Double, for habit: Habit, on date: Date = .now) -> HabitLog? {
        let day = date.normalizedDay()
        if value <= 0 {
            if let existing = dayLog(for: habit, on: day) {
                modelContext.delete(existing)
                save()
            }
            return nil
        }
        if let existing = dayLog(for: habit, on: day) {
            existing.value = value
            existing.loggedAt = .now
            save()
            return existing
        }
        let log = HabitLog(date: day, value: value, habit: habit)
        modelContext.insert(log)
        save()
        return log
    }

    /// Adds `delta` to the day's value (used by counted "+1" and timed sessions).
    @discardableResult
    func increment(_ habit: Habit, by delta: Double, on date: Date = .now) -> HabitLog? {
        let current = value(for: habit, on: date)
        return setValue(max(0, current + delta), for: habit, on: date)
    }

    /// Toggles a binary habit between complete (dailyTarget) and cleared.
    @discardableResult
    func toggleBinary(_ habit: Habit, on date: Date = .now) -> Bool {
        let isComplete = value(for: habit, on: date) >= habit.dailyTarget && habit.dailyTarget > 0
        if isComplete {
            setValue(0, for: habit, on: date)
            return false
        }
        setValue(habit.dailyTarget, for: habit, on: date)
        return true
    }

    // MARK: - Daily Tasks

    /// Tasks for a given day — high priority first, then earliest time anchor.
    func tasks(on date: Date) -> [DailyTask] {
        let day = date.normalizedDay()
        let descriptor = FetchDescriptor<DailyTask>(
            predicate: #Predicate { $0.date == day && !$0.isTemplate }
        )
        let fetched = (try? modelContext.fetch(descriptor)) ?? []
        return fetched.sorted { lhs, rhs in
            if lhs.priority.sortWeight != rhs.priority.sortWeight {
                return lhs.priority.sortWeight > rhs.priority.sortWeight
            }
            return (lhs.timeAnchor ?? .distantFuture) < (rhs.timeAnchor ?? .distantFuture)
        }
    }

    /// Template tasks the user can activate each morning.
    func templateTasks() -> [DailyTask] {
        let descriptor = FetchDescriptor<DailyTask>(
            predicate: #Predicate { $0.isTemplate }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    @discardableResult
    func createTask(
        title: String,
        on date: Date = .now,
        priority: TaskPriority = .medium,
        timeAnchor: Date? = nil,
        isTemplate: Bool = false
    ) -> DailyTask {
        let task = DailyTask(
            title: title,
            date: date.normalizedDay(),
            priority: priority,
            timeAnchor: timeAnchor,
            isTemplate: isTemplate
        )
        modelContext.insert(task)
        save()
        return task
    }

    /// Toggles completion and stamps/clears the completion time.
    func toggleTask(_ task: DailyTask) {
        task.isCompleted.toggle()
        task.completedAt = task.isCompleted ? .now : nil
        save()
    }

    func deleteTask(_ task: DailyTask) {
        modelContext.delete(task)
        save()
    }

    // MARK: - Persistence

    func save() {
        guard modelContext.hasChanges else { return }
        do {
            try modelContext.save()
        } catch {
            print("SequenceRepository: save failed — \(error)")
        }
    }
}
