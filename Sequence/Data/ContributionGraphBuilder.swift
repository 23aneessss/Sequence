//
//  ContributionGraphBuilder.swift
//  Sequence
//
//  Produces the week-aligned cell grid for the Sequence graph.
//  Reference: app_concept.md §2.1 / §10.3 (graphCells).
//
//  Output is COLUMN-MAJOR: every consecutive 7 cells form one week column,
//  oldest week first. Fed straight into a `LazyHGrid(rows: 7)`, this renders as
//  GitHub-style columns with the most recent week on the right.
//

import Foundation

struct ContributionGraphBuilder {

    var calendar: Calendar = .sequence
    /// Week-start weekday: 1 = Sunday (default) … 2 = Monday. Reference: app_concept.md §9.4.
    var weekStartsOn: Int = 1
    private let intensity = IntensityEngine()

    /// Number of rows in the grid (one per weekday).
    let rowCount = 7

    // MARK: - Public

    /// Rolling `dayCount`-day grid for a habit, reading values from its logs.
    func cells(for habit: Habit, endingOn today: Date = .now, dayCount: Int = 365) -> [GraphCell] {
        var values: [Date: Double] = [:]
        for log in habit.logs where log.value != 0 {
            values[log.date.normalizedDay(calendar)] = log.value
        }
        return cells(config: habit, values: values, endingOn: today, dayCount: dayCount)
    }

    /// Testable core: builds the grid from an explicit day→value map plus the
    /// habit's intensity configuration.
    func cells(config habit: Habit, values: [Date: Double],
               endingOn today: Date = .now, dayCount: Int = 365) -> [GraphCell] {
        let end = today.normalizedDay(calendar)
        guard let rangeStart = calendar.date(byAdding: .day, value: -(dayCount - 1), to: end) else {
            return []
        }
        let gridStart = weekStart(onOrBefore: rangeStart)
        let gridEnd = weekEnd(onOrAfter: end)

        var result: [GraphCell] = []
        var cursor = gridStart
        while cursor <= gridEnd {
            let inRange = cursor >= rangeStart && cursor <= end
            if inRange {
                let value = values[cursor] ?? 0
                let level = intensity.level(value: value, for: habit)
                result.append(GraphCell(date: cursor, level: level, value: value, isInRange: true))
            } else {
                result.append(.padding(cursor))
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return result
    }

    /// The number of week columns a flat grid occupies.
    func columnCount(for cells: [GraphCell]) -> Int {
        Int(ceil(Double(cells.count) / Double(rowCount)))
    }

    /// Builds a column-major grid from a precomputed per-day (level, value) map.
    /// Used by graphs whose intensity isn't derived from a habit (e.g. the Task
    /// Contribution Graph, which maps a completion rate to a level).
    func cells(dayValues: [Date: (level: IntensityLevel, value: Double)],
               endingOn today: Date = .now, dayCount: Int = 365) -> [GraphCell] {
        let end = today.normalizedDay(calendar)
        guard let rangeStart = calendar.date(byAdding: .day, value: -(dayCount - 1), to: end) else {
            return []
        }
        let gridStart = weekStart(onOrBefore: rangeStart)
        let gridEnd = weekEnd(onOrAfter: end)

        var result: [GraphCell] = []
        var cursor = gridStart
        while cursor <= gridEnd {
            if cursor >= rangeStart && cursor <= end {
                let entry = dayValues[cursor] ?? (.empty, 0)
                result.append(GraphCell(date: cursor, level: entry.level, value: entry.value, isInRange: true))
            } else {
                result.append(.padding(cursor))
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return result
    }

    // MARK: - Week alignment

    private func weekStart(onOrBefore date: Date) -> Date {
        let weekday = calendar.component(.weekday, from: date)
        let diff = (weekday - weekStartsOn + 7) % 7
        return calendar.date(byAdding: .day, value: -diff, to: date.normalizedDay(calendar)) ?? date
    }

    private func weekEnd(onOrAfter date: Date) -> Date {
        let start = weekStart(onOrBefore: date)
        return calendar.date(byAdding: .day, value: 6, to: start) ?? date
    }
}
