//
//  GraphDemoView.swift
//  Sequence
//
//  Phase 4 visual harness. Seeds a throwaway store with a year of realistic
//  activity so the Sequence graph, sparkline, and streak bar can be verified on
//  device. Replaced by the real Today dashboard in Phase 5.
//

import SwiftUI
import SwiftData

struct GraphDemoView: View {
    @State private var container: ModelContainer?
    @State private var habit: Habit?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SequenceSpacing.section) {
                Text("Sequence").sequenceStyle(.appTitle)

                if let habit {
                    VStack(alignment: .leading, spacing: SequenceSpacing.item) {
                        HStack(spacing: SequenceSpacing.item) {
                            Circle().fill(Color(hex: habit.colorHex)).frame(width: 12, height: 12)
                            Text(habit.name).sequenceTextStyle(.sectionHeader)
                        }
                        MiniSparklineView(habit: habit)
                    }
                    StreakBarView(habit: habit)
                    ContributionGraphView(habit: habit)
                    Text("Pinch to zoom · tap a square").sequenceTextStyle(.subtext)
                } else {
                    ShimmerView(cornerRadius: SequenceRadius.card).frame(height: 140)
                }
            }
            .padding(SequenceSpacing.screenMargin)
        }
        .background(SequenceColor.background.ignoresSafeArea())
        .task { seedIfNeeded() }
    }

    private func seedIfNeeded() {
        guard container == nil else { return }
        do {
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("seq-demo-\(UUID().uuidString).store")
            let config = ModelConfiguration(schema: SequenceModelContainer.schema, url: url)
            let container = try ModelContainer(for: SequenceModelContainer.schema, configurations: [config])
            self.container = container
            let repo = SequenceRepository(modelContext: container.mainContext)
            self.habit = makeSeededHabit(using: repo)
        } catch {
            print("GraphDemoView: failed to seed — \(error)")
        }
    }

    private func makeSeededHabit(using repo: SequenceRepository) -> Habit {
        let habit = repo.createHabit(
            name: "Pushups", iconIdentifier: "figure.strengthtraining.traditional",
            colorHex: "48A69E", type: .counted, unit: "reps",
            dailyTarget: 100, overachieveTarget: 150, thresholds: [25, 50, 75]
        )
        habit.createdAt = Calendar.sequence.date(byAdding: .day, value: -365, to: .now) ?? .now

        var generator = SystemRandomNumberGenerator()
        let calendar = Calendar.sequence
        let today = Date.now.normalizedDay(calendar)
        for offset in 0..<365 {
            // ~70% of days have activity, weighted toward fuller days.
            guard Int.random(in: 0..<100, using: &generator) < 70 else { continue }
            let date = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            let value = Double(Int.random(in: 10...160, using: &generator))
            repo.setValue(value, for: habit, on: date)
        }
        return habit
    }
}
