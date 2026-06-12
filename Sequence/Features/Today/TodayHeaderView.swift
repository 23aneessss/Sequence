//
//  TodayHeaderView.swift
//  Sequence
//
//  Dashboard header: a personal, time-aware greeting plus the day's at-a-glance
//  progress. Reference: app_concept.md §8.1.
//

import SwiftUI

struct TodayHeaderView: View {
    let habits: [Habit]

    @Environment(AuthManager.self) private var auth
    private let intensity = IntensityEngine()

    private var completedToday: Int {
        habits.filter { intensity.level(for: $0, on: .now) >= .full }.count
    }

    private var allDone: Bool { !habits.isEmpty && completedToday == habits.count }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        let part: String
        switch hour {
        case 5..<12:  part = "Good morning"
        case 12..<17: part = "Good afternoon"
        case 17..<22: part = "Good evening"
        default:      part = "Hello"
        }
        let name = auth.displayName.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? part : "\(part), \(name)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SequenceSpacing.half) {
            Text(greeting).sequenceTextStyle(.greeting)
            Text(Date.now.formatted(.dateTime.weekday(.wide).month().day()))
                .sequenceTextStyle(.subtext)
            if !habits.isEmpty { progressPill }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var progressPill: some View {
        HStack(spacing: SequenceSpacing.half) {
            Image(systemName: allDone ? "checkmark.seal.fill" : "circle.lefthalf.filled")
                .font(.system(size: 13, weight: .semibold))
            Text(allDone
                 ? "All \(habits.count) done — perfect day"
                 : "\(completedToday) of \(habits.count) complete today")
                .sequenceTextStyle(.habitTitle)
        }
        .foregroundStyle(allDone ? SequenceColor.mintTeal : SequenceColor.accentTeal)
        .padding(.vertical, SequenceSpacing.half)
        .padding(.horizontal, SequenceSpacing.item)
        .background(
            Capsule().fill((allDone ? SequenceColor.mintTeal : SequenceColor.accentTeal).opacity(0.12))
        )
        .padding(.top, SequenceSpacing.half)
    }
}
