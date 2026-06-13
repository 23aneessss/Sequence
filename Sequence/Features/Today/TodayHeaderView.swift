//
//  TodayHeaderView.swift
//  Sequence
//
//  Dashboard hero: a personal, time-aware greeting on a teal gradient with the
//  day's progress. Reference: app_concept.md §8.1.
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
            Text(greeting)
                .sequenceTextStyle(.greeting)
                .foregroundStyle(.white)
            Text(Date.now.formatted(.dateTime.weekday(.wide).month().day()))
                .sequenceTextStyle(.subtext)
                .foregroundStyle(.white.opacity(0.85))
            if !habits.isEmpty { progressBar }
        }
        .padding(SequenceSpacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [SequenceColor.mintTeal, SequenceColor.accentTeal],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: SequenceRadius.card, style: .continuous))
        .shadow(color: SequenceColor.accentTeal.opacity(0.25), radius: 14, x: 0, y: 6)
    }

    private var progressBar: some View {
        let total = habits.count
        let fraction = total > 0 ? Double(completedToday) / Double(total) : 0
        return VStack(alignment: .leading, spacing: SequenceSpacing.half) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.25))
                    Capsule().fill(.white)
                        .frame(width: max(8, geo.size.width * fraction))
                }
            }
            .frame(height: 8)
            .animation(.sequenceFluid, value: completedToday)
            Text(allDone
                 ? "Perfect day — all \(total) done"
                 : "\(completedToday) of \(total) complete today")
                .sequenceTextStyle(.subtext)
                .foregroundStyle(.white)
        }
        .padding(.top, SequenceSpacing.item)
    }
}
