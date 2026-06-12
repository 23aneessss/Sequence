//
//  SequenceModelContainer.swift
//  Sequence
//
//  Central definition of the persistence schema and container factory.
//  One source of truth so the app and the test suite stay in lockstep.
//

import Foundation
import SwiftData

enum SequenceModelContainer {

    /// The full model schema. Add new `@Model` types here as phases land.
    static let schema = Schema([
        Habit.self,
        HabitLog.self,
        DailyTask.self
    ])

    /// The app's on-disk container.
    static func live() throws -> ModelContainer {
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try ModelContainer(for: schema, configurations: [config])
    }
}
