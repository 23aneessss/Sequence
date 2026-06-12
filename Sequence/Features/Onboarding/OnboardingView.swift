//
//  OnboardingView.swift
//  Sequence
//
//  Five-screen first-launch walkthrough. Reference: app_concept.md §7.2.
//  Paged TabView with custom indicators. Screen 3 creates a real habit; screen 4
//  requests real notification permission.
//

import SwiftUI

struct OnboardingView: View {
    var onComplete: () -> Void

    @Environment(SequenceRepository.self) private var repo
    @Environment(NotificationManager.self) private var notifications

    @State private var page = 0
    @State private var habitName = ""
    @State private var habitColor = DefaultPalette.defaultHex

    private let lastPage = 4

    var body: some View {
        ZStack {
            SequenceColor.background.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    OnboardingConceptScreen().tag(0)
                    OnboardingGraphScreen().tag(1)
                    OnboardingHabitScreen(name: $habitName, colorHex: $habitColor).tag(2)
                    OnboardingNotificationsScreen().tag(3)
                    OnboardingReadyScreen().tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.sequenceFluid, value: page)

                controls
            }
        }
    }

    private var controls: some View {
        VStack(spacing: SequenceSpacing.section) {
            pageDots
            if page == lastPage {
                PrimaryButton(title: "Start Sequence") { finish() }
            } else {
                PrimaryButton(title: nextTitle, isEnabled: canAdvance) {
                    withAnimation(.sequenceFluid) { page += 1 }
                }
            }
        }
        .padding(SequenceSpacing.screenMargin)
    }

    private var pageDots: some View {
        HStack(spacing: SequenceSpacing.item) {
            ForEach(0...lastPage, id: \.self) { i in
                Capsule()
                    .fill(i == page ? SequenceColor.accentTeal : SequenceColor.surfaceSecondary)
                    .frame(width: i == page ? 22 : 8, height: 8)
                    .animation(.sequenceMicro, value: page)
            }
        }
    }

    private var nextTitle: String { page == 2 ? "Create & continue" : "Continue" }

    /// The first-habit screen requires a name before advancing.
    private var canAdvance: Bool {
        page != 2 || !habitName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func finish() {
        ensureFirstHabit()
        Task { await notifications.rescheduleAll() }
        onComplete()
    }

    /// Creates the onboarding habit if a name was entered and it doesn't exist yet.
    private func ensureFirstHabit() {
        let trimmed = habitName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !repo.habits.contains(where: { $0.name == trimmed }) else { return }
        repo.createHabit(name: trimmed, colorHex: habitColor, type: .binary,
                         schedule: .daily)
    }
}
