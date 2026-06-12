//
//  ExportPaletteTests.swift
//  SequenceTests
//
//  Phase 7/8: JSON export shape, palette add/remove, and stats helpers.
//

import XCTest
import SwiftData
@testable import Sequence

final class ExportPaletteTests: XCTestCase {

    private var retained: [ModelContainer] = []
    private var tempURLs: [URL] = []

    override func tearDownWithError() throws {
        retained.removeAll()
        for url in tempURLs { try? FileManager.default.removeItem(at: url) }
        tempURLs.removeAll()
    }

    @MainActor
    private func makeRepo() throws -> SequenceRepository {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("seq-ep-\(UUID().uuidString).store")
        tempURLs.append(url)
        let config = ModelConfiguration(schema: SequenceModelContainer.schema, url: url)
        let container = try ModelContainer(for: SequenceModelContainer.schema, configurations: [config])
        retained.append(container)
        return SequenceRepository(modelContext: container.mainContext)
    }

    // MARK: - Export

    @MainActor
    func testJSONExportContainsHabitsAndLogs() throws {
        let repo = try makeRepo()
        let habit = repo.createHabit(name: "Pushups", type: .counted, unit: "reps", dailyTarget: 100)
        repo.setValue(87, for: habit, on: .now)
        repo.createTask(title: "Inbox zero")

        let data = try XCTUnwrap(DataExporter.makeJSON(habits: repo.allHabits(includeArchived: true),
                                                       tasks: repo.allTasks()))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let habits = try XCTUnwrap(json["habits"] as? [[String: Any]])
        XCTAssertEqual(habits.first?["name"] as? String, "Pushups")
        let logs = try XCTUnwrap(habits.first?["logs"] as? [[String: Any]])
        XCTAssertEqual(logs.first?["value"] as? Double, 87)
        XCTAssertNotNil(json["tasks"])
        XCTAssertNotNil(json["exportedAt"])
    }

    // MARK: - Palette

    func testPaletteSeedsDefaultsAddAndRemove() {
        UserDefaults.standard.removeObject(forKey: "sequence.palette")
        let palette = PaletteStore()
        XCTAssertEqual(palette.swatches.count, DefaultPalette.swatches.count)

        palette.add(name: "Night", hex: "#112233")
        XCTAssertTrue(palette.swatches.contains { $0.hex == "112233" })

        // Duplicate + malformed are rejected.
        let count = palette.swatches.count
        palette.add(name: "Dup", hex: "112233")
        palette.add(name: "Bad", hex: "XYZ")
        XCTAssertEqual(palette.swatches.count, count)

        let added = try? XCTUnwrap(palette.swatches.first { $0.hex == "112233" })
        if let added { palette.remove(added) }
        XCTAssertFalse(palette.swatches.contains { $0.hex == "112233" })
        UserDefaults.standard.removeObject(forKey: "sequence.palette")
    }

    // MARK: - Stats helpers

    @MainActor
    func testCombinedCompletionRate() throws {
        let repo = try makeRepo()
        let a = repo.createHabit(name: "A", type: .binary, dailyTarget: 1)
        let b = repo.createHabit(name: "B", type: .binary, dailyTarget: 1)
        repo.setValue(1, for: a, on: .now) // 1 of 2 complete today
        let rates = StatsEngine().combinedCompletion(habits: repo.habits, dayCount: 1)
        XCTAssertEqual(rates[Date.now.normalizedDay()] ?? -1, 0.5, accuracy: 0.001)
    }
}
