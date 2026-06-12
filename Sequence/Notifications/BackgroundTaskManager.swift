//
//  BackgroundTaskManager.swift
//  Sequence
//
//  Registers and drives the periodic BGAppRefreshTask. Reference: app_concept.md §6.2.
//  On each refresh it rebuilds the next batch of notifications (so streak-at-risk
//  alerts stay accurate) and refreshes repository state.
//
//  Registration must happen before the app finishes launching, so this is wired
//  up in SequenceApp.init.
//

import Foundation
import BackgroundTasks

final class BackgroundTaskManager {

    static let refreshIdentifier = "com.sequence.app.refresh"

    private weak var notifications: NotificationManager?
    private weak var repo: SequenceRepository?

    /// Registers the launch handler. Call once, before launch completes.
    func register(notifications: NotificationManager, repo: SequenceRepository) {
        self.notifications = notifications
        self.repo = repo
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.refreshIdentifier, using: nil) { [weak self] task in
            guard let appRefresh = task as? BGAppRefreshTask else { return }
            self?.handle(appRefresh)
        }
    }

    /// Asks the system to schedule the next refresh (~ every few hours).
    func scheduleNextRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.refreshIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 4 * 60 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // Common on Simulator (no background scheduling) — not fatal.
            print("BackgroundTaskManager: could not schedule refresh — \(error)")
        }
    }

    private func handle(_ task: BGAppRefreshTask) {
        scheduleNextRefresh() // chain the next one

        let work = Task {
            await MainActor.run { self.repo?.refresh() }
            await self.notifications?.rescheduleAll()
            task.setTaskCompleted(success: true)
        }
        task.expirationHandler = { work.cancel() }
    }
}
