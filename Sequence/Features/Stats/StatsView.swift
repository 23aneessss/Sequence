//
//  StatsView.swift
//  Sequence
//
//  Tab 3 — the Momentum Dashboard. Reference: app_concept.md §5.
//

import SwiftUI

struct StatsView: View {
    @Environment(SequenceRepository.self) private var repo
    @Environment(SettingsStore.self) private var settings

    @State private var selectedHabit: Habit?
    @State private var showYearly = false
    @State private var isLoading = true
    @Namespace private var detailNamespace

    private let stats = StatsEngine()

    var body: some View {
        ZStack {
            SequenceColor.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: SequenceSpacing.section) {
                    Text("Stats").sequenceStyle(.appTitle)
                    if repo.habits.isEmpty {
                        DashedEmptyState(title: "Nothing to measure yet",
                                         message: "Create a habit to start building momentum.")
                    } else if isLoading {
                        skeleton
                    } else {
                        loadedContent
                    }
                }
                .padding(SequenceSpacing.screenMargin)
            }
        }
        .task {
            // Brief skeleton beat, then reveal computed analytics.
            try? await Task.sleep(nanoseconds: 350_000_000)
            withAnimation(.sequenceFluid) { isLoading = false }
        }
        .sheet(item: $selectedHabit) { habit in
            HabitDetailView(habit: habit, namespace: detailNamespace) { selectedHabit = nil }
        }
        .fullScreenCover(isPresented: $showYearly) {
            YearlyReviewView(habits: repo.habits)
        }
    }

    private var loadedContent: some View {
        VStack(alignment: .leading, spacing: SequenceSpacing.section) {
            MomentumDashboardView(habits: repo.habits, weekStartsOn: settings.weekStartsOn)
            SeriousnessGaugeView(percent: stats.seriousnessIndex(habits: repo.habits))

            VStack(alignment: .leading, spacing: SequenceSpacing.item) {
                Text("Per-habit").sequenceTextStyle(.sectionHeader)
                ForEach(repo.habits, id: \.id) { habit in
                    PerHabitStatCard(habit: habit) { selectedHabit = habit }
                }
            }

            Button { showYearly = true } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Year in Sequence").sequenceTextStyle(.habitTitle)
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(SequenceColor.textSecondary)
                }
                .foregroundStyle(SequenceColor.textPrimary)
                .padding(SequenceSpacing.cardPadding)
                .background(RoundedRectangle(cornerRadius: SequenceRadius.card, style: .continuous)
                    .fill(SequenceColor.surfacePrimary))
            }
            .buttonStyle(SequencePressStyle())
        }
    }

    private var skeleton: some View {
        VStack(spacing: SequenceSpacing.section) {
            ShimmerView(cornerRadius: SequenceRadius.card).frame(height: 160)
            ShimmerView(cornerRadius: SequenceRadius.card).frame(height: 200)
            ShimmerView(cornerRadius: SequenceRadius.card).frame(height: 96)
            ShimmerView(cornerRadius: SequenceRadius.card).frame(height: 96)
        }
    }
}
