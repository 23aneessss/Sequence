//
//  GraphTests.swift
//  SequenceTests
//
//  Phase 4: contribution-graph builder correctness — week alignment,
//  column-major ordering, range sizing, and value→level placement.
//

import XCTest
@testable import Sequence

final class GraphTests: XCTestCase {

    private let cal = Calendar.sequence
    private func day(_ offset: Int) -> Date {
        cal.date(byAdding: .day, value: offset, to: Date.now.normalizedDay(cal))!
    }

    private func makeHabit() -> Habit {
        Habit(name: "Pushups", type: .counted,
              dailyTarget: 100, overachieveTarget: 150, thresholds: [25, 50, 75])
    }

    func testGridIsWholeWeeksColumnMajor() {
        let builder = ContributionGraphBuilder(weekStartsOn: 1)
        let cells = builder.cells(config: makeHabit(), values: [:], dayCount: 365)
        XCTAssertEqual(cells.count % 7, 0, "Grid must be whole 7-day columns")
    }

    func testFirstAndLastCellsAlignToWeekBoundaries() {
        let builder = ContributionGraphBuilder(weekStartsOn: 1) // Sunday
        let cells = builder.cells(config: makeHabit(), values: [:], dayCount: 365)
        let firstWeekday = cal.component(.weekday, from: cells.first!.date)
        let lastWeekday = cal.component(.weekday, from: cells.last!.date)
        XCTAssertEqual(firstWeekday, 1, "First cell should be a Sunday")
        XCTAssertEqual(lastWeekday, 7, "Last cell should be a Saturday")
    }

    func testInRangeCountMatchesDayCount() {
        let builder = ContributionGraphBuilder()
        let cells = builder.cells(config: makeHabit(), values: [:], dayCount: 365)
        XCTAssertEqual(cells.filter(\.isInRange).count, 365)
    }

    func testTodayIsLastInRangeCell() {
        let builder = ContributionGraphBuilder()
        let cells = builder.cells(config: makeHabit(), values: [:], dayCount: 90)
        let lastInRange = cells.last { $0.isInRange }
        XCTAssertEqual(lastInRange?.date, day(0))
    }

    func testValuesMapToCorrectLevels() {
        let builder = ContributionGraphBuilder()
        let habit = makeHabit()
        let values: [Date: Double] = [
            day(0): 150,   // overachieved
            day(-1): 100,  // full
            day(-2): 60,   // low
            day(-3): 0     // empty
        ]
        let cells = builder.cells(config: habit, values: values, dayCount: 30)
        func level(_ offset: Int) -> IntensityLevel? {
            cells.first { $0.date == day(offset) }?.level
        }
        XCTAssertEqual(level(0), .overachieved)
        XCTAssertEqual(level(-1), .full)
        XCTAssertEqual(level(-2), .low)
        XCTAssertEqual(level(-3), .empty)
    }

    func testColumnCount() {
        let builder = ContributionGraphBuilder()
        let cells = builder.cells(config: makeHabit(), values: [:], dayCount: 91)
        XCTAssertEqual(builder.columnCount(for: cells), cells.count / 7)
    }
}
