//
//  TodayHeaderView.swift
//  Sequence
//
//  Dashboard header with the day's at-a-glance summary. Reference: app_concept.md §8.1.
//

import SwiftUI

struct TodayHeaderView: View {
    let habits: [Habit]

    private let intensity = IntensityEngine()

    private var completedToday: Int {
        habits.filter { intensity.level(for: $0, on: .now) >= .full }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SequenceSpacing.half) {
            Text("Sequence").sequenceStyle(.appTitle)
            if habits.isEmpty {
                Text(Date.now.formatted(.dateTime.weekday(.wide).month().day()))
                    .sequenceTextStyle(.subtext)
            } else {
                Text("\(completedToday) of \(habits.count) complete today")
                    .sequenceTextStyle(.subtext)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
