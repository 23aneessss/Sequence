//
//  OnboardingScreens.swift
//  Sequence
//
//  The five onboarding pages. Reference: app_concept.md §7.2.
//

import SwiftUI

// MARK: - Shared chrome

private struct OnboardingScaffold<Top: View>: View {
    let headline: String
    let subtext: String
    @ViewBuilder var top: () -> Top

    var body: some View {
        VStack(spacing: SequenceSpacing.section) {
            Spacer()
            top()
            VStack(spacing: SequenceSpacing.item) {
                Text(headline).sequenceTextStyle(.sectionHeader).multilineTextAlignment(.center)
                Text(subtext).sequenceTextStyle(.subtext).multilineTextAlignment(.center)
            }
            .padding(.horizontal, SequenceSpacing.section)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Screen 1 — Concept

struct OnboardingConceptScreen: View {
    var body: some View {
        OnboardingScaffold(headline: "Every day is a square.",
                           subtext: "Sequence tracks your habits the way GitHub tracks code — a living visual record of consistency.") {
            SequenceLogo(size: 150, animated: true)
        }
    }
}

// MARK: - Screen 2 — Interactive graph demo

struct OnboardingGraphScreen: View {
    @State private var levels: [Int] = Array(repeating: 0, count: 5)
    var body: some View {
        OnboardingScaffold(headline: "The more you do, the deeper the color.",
                           subtext: "Each habit has its own graph. Tap a square to fill it. Build something worth looking at.") {
            HStack(spacing: SequenceSpacing.item) {
                ForEach(0..<5, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(ColorScaleEngine.color(forHex: DefaultPalette.defaultHex, level: IntensityLevel(rawValue: levels[i]) ?? .empty))
                        .frame(width: 44, height: 44)
                        .onTapGesture {
                            UISelectionFeedbackGenerator().selectionChanged()
                            withAnimation(.sequenceMicro) { levels[i] = (levels[i] + 1) % 6 }
                        }
                }
            }
        }
    }
}

// MARK: - Screen 3 — First habit

struct OnboardingHabitScreen: View {
    @Binding var name: String
    @Binding var colorHex: String
    @Environment(PaletteStore.self) private var palette

    var body: some View {
        OnboardingScaffold(headline: "What do you want to build?",
                           subtext: "Name your first habit and pick its color. This one's real.") {
            VStack(spacing: SequenceSpacing.item) {
                TextField("e.g. Read, Meditate, Run", text: $name)
                    .multilineTextAlignment(.center)
                    .sequenceTextStyle(.habitTitle)
                    .padding(SequenceSpacing.cardPadding)
                    .background(RoundedRectangle(cornerRadius: SequenceRadius.small, style: .continuous)
                        .fill(SequenceColor.surfaceSecondary))
                    .padding(.horizontal, SequenceSpacing.section)
                HStack(spacing: SequenceSpacing.item) {
                    ForEach(palette.swatches.prefix(6)) { swatch in
                        Button { colorHex = swatch.hex } label: {
                            Circle().fill(Color(hex: swatch.hex)).frame(width: 34, height: 34)
                                .overlay(Circle().strokeBorder(SequenceColor.textPrimary,
                                                               lineWidth: colorHex == swatch.hex ? 3 : 0))
                        }
                        .buttonStyle(SequencePressStyle())
                    }
                }
            }
        }
    }
}

// MARK: - Screen 4 — Notifications

struct OnboardingNotificationsScreen: View {
    @Environment(NotificationManager.self) private var notifications
    @State private var requested = false

    var body: some View {
        OnboardingScaffold(headline: "Let Sequence remind you.",
                           subtext: "Streak-at-risk alerts keep your chain alive. You'll only hear from us when it matters.") {
            VStack(spacing: SequenceSpacing.section) {
                Image(systemName: requested ? "bell.badge.fill" : "bell.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(SequenceColor.accentTeal)
                if requested {
                    Label("Reminders on", systemImage: "checkmark.circle.fill")
                        .sequenceTextStyle(.subtext)
                        .foregroundStyle(SequenceColor.mintTeal)
                } else {
                    PrimaryButton(title: "Enable Reminders") {
                        Task { await notifications.requestAuthorization(); requested = true }
                    }
                    .frame(width: 220)
                }
            }
        }
    }
}

// MARK: - Screen 5 — Ready

struct OnboardingReadyScreen: View {
    var body: some View {
        OnboardingScaffold(headline: "Your first square is waiting.",
                           subtext: "Today is Day 1. Make it green.") {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(20), spacing: 4), count: 7), spacing: 4) {
                ForEach(0..<28, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(SequenceColor.surfaceSecondary)
                        .frame(width: 20, height: 20)
                }
            }
            .frame(width: 7 * 24)
        }
    }
}
