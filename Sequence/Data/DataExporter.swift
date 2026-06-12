//
//  DataExporter.swift
//  Sequence
//
//  Exports all user data as structured JSON. Reference: app_concept.md §10.4.
//

import Foundation

enum DataExporter {

    // Codable mirrors of the persistent models, shaped to the §10.4 schema.
    private struct Export: Encodable {
        let exportedAt: String
        let habits: [HabitExport]
        let tasks: [TaskExport]
    }
    private struct HabitExport: Encodable {
        let id: String
        let name: String
        let type: String
        let unit: String?
        let logs: [LogExport]
    }
    private struct LogExport: Encodable { let date: String; let value: Double }
    private struct TaskExport: Encodable {
        let title: String; let date: String; let isCompleted: Bool; let priority: String
    }

    private static let dayFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        return f
    }()

    /// Builds the JSON export data, or nil if encoding fails.
    static func makeJSON(habits: [Habit], tasks: [DailyTask]) -> Data? {
        let habitExports = habits.map { habit in
            HabitExport(
                id: habit.id.uuidString,
                name: habit.name,
                type: habit.type.rawValue,
                unit: habit.unit,
                logs: habit.sortedLogs.map { LogExport(date: dayFormatter.string(from: $0.date), value: $0.value) }
            )
        }
        let taskExports = tasks.map {
            TaskExport(title: $0.title, date: dayFormatter.string(from: $0.date),
                       isCompleted: $0.isCompleted, priority: $0.priority.rawValue)
        }
        let payload = Export(exportedAt: ISO8601DateFormatter().string(from: .now),
                             habits: habitExports, tasks: taskExports)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(payload)
    }

    /// Writes the export to a temp file and returns its URL (for ShareLink).
    static func writeTempFile(habits: [Habit], tasks: [DailyTask]) -> URL? {
        guard let data = makeJSON(habits: habits, tasks: tasks) else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("sequence-export.json")
        do {
            try data.write(to: url)
            return url
        } catch {
            print("DataExporter: write failed — \(error)")
            return nil
        }
    }
}
