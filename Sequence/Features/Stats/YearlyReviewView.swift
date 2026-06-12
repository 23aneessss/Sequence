//
//  YearlyReviewView.swift
//  Sequence
//
//  Shareable "Year in Sequence" summary. Reference: app_concept.md §5.3.
//  Rendered to an image via ImageRenderer and shared via ShareLink.
//

import SwiftUI

struct YearlyReviewView: View {
    let habits: [Habit]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale

    @State private var shareImage: ShareableImage?

    var body: some View {
        ZStack {
            SequenceColor.background.ignoresSafeArea()
            VStack(spacing: SequenceSpacing.section) {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26)).foregroundStyle(SequenceColor.textSecondary)
                    }
                }
                ScrollView { YearInSequenceCard(habits: habits).padding(SequenceSpacing.screenMargin) }
                exportButton
            }
            .padding(SequenceSpacing.screenMargin)
        }
        .sheet(item: $shareImage) { item in
            ShareSheet(image: item.image)
        }
    }

    private var exportButton: some View {
        PrimaryButton(title: "Export as image") { renderAndShare() }
            .padding(.horizontal, SequenceSpacing.screenMargin)
    }

    @MainActor private func renderAndShare() {
        let renderer = ImageRenderer(content:
            YearInSequenceCard(habits: habits).frame(width: 360).padding(20).background(SequenceColor.background)
        )
        renderer.scale = displayScale
        if let uiImage = renderer.uiImage {
            shareImage = ShareableImage(image: uiImage)
        }
    }
}

/// The visual summary card. Reference: app_concept.md §5.3.
struct YearInSequenceCard: View {
    let habits: [Habit]
    private let streak = StreakEngine()

    private var totalActiveDays: Int {
        habits.reduce(into: Set<Date>()) { $0.formUnion($1.activeDates) }.count
    }
    private var bestStreak: Int { habits.map { streak.bestStreak(for: $0) }.max() ?? 0 }
    private var topHabit: Habit? {
        habits.max { streak.totalActiveDays(for: $0) < streak.totalActiveDays(for: $1) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SequenceSpacing.section) {
            VStack(alignment: .leading, spacing: SequenceSpacing.half) {
                Text("Year in Sequence").sequenceStyle(.appTitle)
                Text(Date.now.formatted(.dateTime.year())).sequenceTextStyle(.subtext)
            }
            HStack(spacing: SequenceSpacing.item) {
                summaryStat("\(totalActiveDays)", "Active days")
                summaryStat("\(bestStreak)", "Best streak")
                summaryStat(topHabit?.name ?? "—", "Top habit")
            }
            ForEach(habits, id: \.id) { habit in
                VStack(alignment: .leading, spacing: SequenceSpacing.half) {
                    HStack(spacing: SequenceSpacing.half) {
                        Circle().fill(Color(hex: habit.colorHex)).frame(width: 10, height: 10)
                        Text(habit.name).sequenceTextStyle(.subtext)
                    }
                    MiniSparklineView(habit: habit, dayCount: 30, cellSize: 8)
                }
            }
        }
        .padding(SequenceSpacing.section)
        .background(RoundedRectangle(cornerRadius: SequenceRadius.card, style: .continuous)
            .fill(SequenceColor.surfacePrimary))
    }

    private func summaryStat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).sequenceTextStyle(.sectionHeader).lineLimit(1).minimumScaleFactor(0.6)
            Text(label).sequenceTextStyle(.subtext)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Wraps a rendered image for `.sheet(item:)`.
private struct ShareableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

/// UIKit share sheet bridge.
private struct ShareSheet: UIViewControllerRepresentable {
    let image: UIImage
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [image], applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
