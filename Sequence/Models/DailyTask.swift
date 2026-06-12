//
//  DailyTask.swift
//  Sequence
//
//  A finite, day-scoped commitment (distinct from a habit). Reference:
//  app_concept.md §4 / §10.2.
//

import Foundation
import SwiftData

@Model
final class DailyTask {
    @Attribute(.unique) var id: UUID

    var title: String
    /// The day this task belongs to, normalized to local midnight.
    var date: Date

    var isCompleted: Bool
    var completedAt: Date?

    var priority: TaskPriority
    /// Optional time-of-day anchor. Reference: app_concept.md §4.3.
    var timeAnchor: Date?
    /// Appears as a greyed-out suggestion each morning. Reference: app_concept.md §4.4.
    var isTemplate: Bool

    init(
        id: UUID = UUID(),
        title: String,
        date: Date,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        priority: TaskPriority = .medium,
        timeAnchor: Date? = nil,
        isTemplate: Bool = false
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.priority = priority
        self.timeAnchor = timeAnchor
        self.isTemplate = isTemplate
    }
}
