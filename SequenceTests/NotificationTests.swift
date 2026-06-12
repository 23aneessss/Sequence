//
//  NotificationTests.swift
//  SequenceTests
//
//  Phase 9: pure scheduling conditions and the Do-Not-Disturb window.
//

import XCTest
@testable import Sequence

final class NotificationTests: XCTestCase {

    // MARK: - Streak-at-risk condition

    func testStreakAtRiskRequiresActiveStreakAndUnlogged() {
        XCTAssertTrue(NotificationManager.shouldScheduleStreakAtRisk(streak: 3, isLoggedToday: false))
        XCTAssertTrue(NotificationManager.shouldScheduleStreakAtRisk(streak: 10, isLoggedToday: false))
    }

    func testStreakAtRiskSuppressedWhenLoggedOrTooShort() {
        XCTAssertFalse(NotificationManager.shouldScheduleStreakAtRisk(streak: 5, isLoggedToday: true),
                       "Already logged today → no alert")
        XCTAssertFalse(NotificationManager.shouldScheduleStreakAtRisk(streak: 2, isLoggedToday: false),
                       "Streak below 3 → no alert")
        XCTAssertFalse(NotificationManager.shouldScheduleStreakAtRisk(streak: 0, isLoggedToday: false))
    }

    // MARK: - Do Not Disturb window (overnight span)

    private func date(hour: Int, minute: Int = 0) -> Date {
        Calendar.sequence.date(bySettingHour: hour, minute: minute, second: 0, of: .now)!
    }

    func testDoNotDisturbOvernightWindow() {
        let settings = SettingsStore()
        settings.dndEnabled = true
        settings.dndStart = date(hour: 22)
        settings.dndEnd = date(hour: 7)

        XCTAssertTrue(settings.isInDoNotDisturb(date(hour: 23)), "23:00 is inside 22:00–07:00")
        XCTAssertTrue(settings.isInDoNotDisturb(date(hour: 3)), "03:00 is inside the overnight window")
        XCTAssertFalse(settings.isInDoNotDisturb(date(hour: 12)), "Noon is outside")
        XCTAssertFalse(settings.isInDoNotDisturb(date(hour: 21)), "21:00 (alert time) is outside by design")
    }

    func testDoNotDisturbDisabled() {
        let settings = SettingsStore()
        settings.dndEnabled = false
        settings.dndStart = date(hour: 22)
        settings.dndEnd = date(hour: 7)
        XCTAssertFalse(settings.isInDoNotDisturb(date(hour: 23)))
    }

    func testMilestoneSet() {
        XCTAssertEqual(NotificationManager.milestones, [7, 14, 30, 60, 90, 180, 365])
    }
}
