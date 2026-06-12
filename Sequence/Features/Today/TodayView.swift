//
//  TodayView.swift
//  Sequence
//
//  Tab 1 — the primary dashboard. Reference: app_concept.md §8.1.
//  Header + 7-day continuity strip + habit cards + FAB. Tapping a card expands
//  it into its detail via a matchedGeometry transition (no nav-stack push, §8.2).
//

import SwiftUI

struct TodayView: View {
    @Environment(SequenceRepository.self) private var repo

    @State private var showCreate = false
    @State private var selected: Habit?
    @State private var showCoachMarks = false
    @AppStorage("sequence.coachMarksSeen") private var coachMarksSeen = false
    @Namespace private var cardNamespace

    var body: some View {
        ZStack {
            SequenceColor.background.ignoresSafeArea()

            if let selected {
                HabitDetailView(habit: selected, namespace: cardNamespace) {
                    withAnimation(.sequenceStructural) { self.selected = nil }
                }
                .zIndex(1)
            } else {
                dashboard
                fab
            }

            if showCoachMarks {
                CoachMarkOverlay(isPresented: $showCoachMarks).zIndex(2)
            }
        }
        .animation(.sequenceStructural, value: selected?.id)
        .sheet(isPresented: $showCreate) {
            HabitCreationSheet()
                .presentationDetents([.fraction(0.6), .large])
        }
        .onChange(of: showCoachMarks) { _, showing in if !showing { coachMarksSeen = true } }
        .task {
            // Show the one-time coaching once there's a habit to point at.
            if !coachMarksSeen && !repo.habits.isEmpty {
                try? await Task.sleep(nanoseconds: 500_000_000)
                withAnimation(.sequenceFluid) { showCoachMarks = true }
            }
        }
    }

    // MARK: - Dashboard

    private var dashboard: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SequenceSpacing.section) {
                TodayHeaderView(habits: repo.habits)

                if repo.habits.isEmpty {
                    DashedEmptyState(
                        title: "No habits yet",
                        message: "Tap + to start your first Sequence. Today is Day 1."
                    )
                    .padding(.top, SequenceSpacing.section)
                } else {
                    ContinuityStripView(habits: repo.habits)
                    habitList
                }
            }
            .padding(SequenceSpacing.screenMargin)
            .padding(.bottom, 80) // clear the FAB
        }
    }

    private var habitList: some View {
        LazyVStack(spacing: SequenceSpacing.item) {
            ForEach(repo.habits, id: \.id) { habit in
                HabitCardView(habit: habit, namespace: cardNamespace) {
                    withAnimation(.sequenceStructural) { selected = habit }
                }
            }
        }
    }

    // MARK: - FAB

    private var fab: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button { showCreate = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(SequenceColor.background)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(SequenceColor.accentTeal))
                        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                }
                .buttonStyle(SequencePressStyle())
                .padding(SequenceSpacing.screenMargin)
            }
        }
    }
}
