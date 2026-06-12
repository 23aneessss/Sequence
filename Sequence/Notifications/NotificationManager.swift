//
//  NotificationManager.swift
//  Sequence
//
//  Local notification scheduling + handling. Reference: app_concept.md §6.
//  Four types: habit reminder, streak-at-risk, morning task summary, milestone.
//  All fire locally via UNUserNotificationCenter — no server.
//

import Foundation
import UserNotifications
import Observation

@Observable
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {

    /// Action identifiers for the rich "Log Now / Snooze" habit category.
    enum Action {
        static let category = "HABIT_REMINDER"
        static let logNow = "LOG_NOW"
        static let snooze = "SNOOZE"
    }
    enum Identifier {
        static func habit(_ id: UUID) -> String { "habit-reminder-\(id.uuidString)" }
        static func streak(_ id: UUID) -> String { "streak-risk-\(id.uuidString)" }
        static func snooze(_ id: UUID) -> String { "snooze-\(id.uuidString)" }
        static let task = "task-morning-summary"
        static let milestonePrefix = "milestone-"
    }

    var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let center = UNUserNotificationCenter.current()
    private weak var repo: SequenceRepository?
    private var settings: SettingsStore?
    private let streak = StreakEngine()

    // MARK: - Setup

    func configure(repo: SequenceRepository, settings: SettingsStore) {
        self.repo = repo
        self.settings = settings
        center.delegate = self
        registerCategories()
        Task { await refreshAuthorizationStatus() }
    }

    private func registerCategories() {
        let logNow = UNNotificationAction(identifier: Action.logNow, title: "Log Now", options: [])
        let snooze = UNNotificationAction(identifier: Action.snooze, title: "Snooze 30 min", options: [])
        let category = UNNotificationCategory(identifier: Action.category,
                                              actions: [logNow, snooze],
                                              intentIdentifiers: [], options: [])
        center.setNotificationCategories([category])
    }

    // MARK: - Authorization

    @discardableResult
    func requestAuthorization() async -> Bool {
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        await refreshAuthorizationStatus()
        return granted
    }

    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        await MainActor.run { self.authorizationStatus = settings.authorizationStatus }
    }

    // MARK: - Pure scheduling conditions (unit-tested)

    /// Type 2 fires only when a streak is at risk: an active streak ≥ 3 with no
    /// activity logged today. Reference: app_concept.md §6.1.
    static func shouldScheduleStreakAtRisk(streak: Int, isLoggedToday: Bool, minStreak: Int = 3) -> Bool {
        streak >= minStreak && !isLoggedToday
    }

    /// Milestone thresholds. Reference: app_concept.md §6.1 (Type 4).
    static let milestones: Set<Int> = [7, 14, 30, 60, 90, 180, 365]

    // MARK: - Rescheduling

    /// Clears and rebuilds all pending notifications (within iOS's 64-request budget).
    /// Reference: app_concept.md §6.2.
    func rescheduleAll() async {
        guard authorizationStatus == .authorized, let repo, let settings else { return }
        center.removeAllPendingNotificationRequests()

        var requests: [UNNotificationRequest] = []
        requests.append(taskSummaryRequest(at: settings.taskReminderTime))

        for habit in await MainActor.run(body: { repo.habits }) {
            if let reminder = habitReminderRequest(for: habit) { requests.append(reminder) }
            if let risk = streakAtRiskRequest(for: habit, settings: settings) { requests.append(risk) }
        }

        // iOS keeps at most 64 pending requests; submit the earliest-firing budget.
        for request in requests.prefix(64) {
            try? await center.add(request)
        }
    }

    // MARK: - Request builders

    func habitReminderRequest(for habit: Habit) -> UNNotificationRequest? {
        guard let time = habit.reminderTime else { return nil }
        let content = UNMutableNotificationContent()
        let s = streak.currentStreak(for: habit)
        content.title = "Time to \(habit.name)"
        content.body = s > 0 ? "You're on a \(s)-day streak — don't break it." : "Build your streak today."
        content.sound = .default
        content.categoryIdentifier = Action.category
        content.userInfo = ["habitID": habit.id.uuidString]

        let comps = Calendar.sequence.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        return UNNotificationRequest(identifier: Identifier.habit(habit.id), content: content, trigger: trigger)
    }

    /// A one-shot 21:00 streak-at-risk alert for today, if conditions hold and the
    /// fire time isn't inside the DND window.
    func streakAtRiskRequest(for habit: Habit, settings: SettingsStore, now: Date = .now) -> UNNotificationRequest? {
        let s = streak.currentStreak(for: habit, asOf: now)
        let loggedToday = habit.value(on: now) > 0
        guard Self.shouldScheduleStreakAtRisk(streak: s, isLoggedToday: loggedToday) else { return nil }

        let calendar = Calendar.sequence
        guard let fire = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: now),
              fire > now, !settings.isInDoNotDisturb(fire, calendar) else { return nil }

        let content = UNMutableNotificationContent()
        content.title = "\(habit.name) streak at risk"
        content.body = "Your \(s)-day streak ends tonight. A few hours left."
        content.sound = .default
        content.categoryIdentifier = Action.category
        content.userInfo = ["habitID": habit.id.uuidString]

        let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        return UNNotificationRequest(identifier: Identifier.streak(habit.id), content: content, trigger: trigger)
    }

    func taskSummaryRequest(at time: Date) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "Good morning"
        content.body = "What will you accomplish today? Plan your task board."
        content.sound = .default
        let comps = Calendar.sequence.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        return UNNotificationRequest(identifier: Identifier.task, content: content, trigger: trigger)
    }

    /// Fires a milestone celebration. Reference: app_concept.md §6.1 (Type 4).
    func sendMilestone(habit: Habit, days: Int) {
        guard authorizationStatus == .authorized, Self.milestones.contains(days) else { return }
        let content = UNMutableNotificationContent()
        content.title = "\(days)-day streak on \(habit.name)"
        content.body = "This is what consistency looks like."
        content.sound = .default
        content.userInfo = ["habitID": habit.id.uuidString]
        let request = UNNotificationRequest(identifier: "\(Identifier.milestonePrefix)\(habit.id)-\(days)",
                                            content: content,
                                            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false))
        center.add(request)
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async
        -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        let info = response.notification.request.content.userInfo
        guard let raw = info["habitID"] as? String, let id = UUID(uuidString: raw) else { return }

        switch response.actionIdentifier {
        case Action.logNow:
            await handleLogNow(habitID: id)
        case Action.snooze:
            scheduleSnooze(habitID: id, content: response.notification.request.content)
        default:
            break
        }
    }

    @MainActor
    private func handleLogNow(habitID: UUID) {
        guard let repo, let habit = repo.habits.first(where: { $0.id == habitID }) else { return }
        if habit.type == .binary {
            if repo.value(for: habit, on: .now) < habit.dailyTarget { repo.toggleBinary(habit) }
        } else {
            repo.increment(habit, by: 1)
        }
        Task { await rescheduleAll() }
    }

    private func scheduleSnooze(habitID: UUID, content: UNNotificationContent) {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 30 * 60, repeats: false)
        let request = UNNotificationRequest(identifier: Identifier.snooze(habitID), content: content, trigger: trigger)
        center.add(request)
    }
}
