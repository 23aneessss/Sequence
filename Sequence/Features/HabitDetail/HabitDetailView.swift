//
//  HabitDetailView.swift
//  Sequence
//
//  Expanded habit view reached by tapping a card. Reference: app_concept.md §5.2,
//  product_design.md §5.3 (matchedGeometry, no nav-stack push).
//

import SwiftUI

struct HabitDetailView: View {
    let habit: Habit
    var namespace: Namespace.ID
    var onClose: () -> Void

    @Environment(SequenceRepository.self) private var repo
    @Environment(SettingsStore.self) private var settings
    @State private var editingCell: GraphCell?

    private let stats = StatsEngine()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SequenceSpacing.section) {
                titleRow
                StreakBarView(habit: habit)

                VStack(alignment: .leading, spacing: SequenceSpacing.item) {
                    Text("Sequence Graph").sequenceTextStyle(.sectionHeader)
                    ContributionGraphView(habit: habit,
                                          weekStartsOn: settings.weekStartsOn,
                                          direction: settings.graphDirection) { cell in editingCell = cell }
                }

                metricsGrid
            }
            .padding(SequenceSpacing.screenMargin)
            .padding(.top, SequenceSpacing.section)
        }
        .background(SequenceColor.background.ignoresSafeArea())
        .matchedGeometryEffect(id: habit.id, in: namespace)
        .sheet(item: $editingCell) { cell in
            CellEditSheet(habit: habit, cell: cell) { newValue in
                repo.setValue(newValue, for: habit, on: cell.date)
            }
            .presentationDetents([.fraction(0.3)])
        }
    }

    private var titleRow: some View {
        HStack(spacing: SequenceSpacing.item) {
            Image(systemName: habit.iconIdentifier)
                .font(.system(size: 20))
                .foregroundStyle(Color(hex: habit.colorHex))
            Text(habit.name).sequenceTextStyle(.sectionHeader)
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(SequenceColor.textSecondary)
            }
            .buttonStyle(SequencePressStyle())
        }
    }

    private var metricsGrid: some View {
        let s = stats.statistics(for: habit)
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        return VStack(alignment: .leading, spacing: SequenceSpacing.item) {
            Text("Statistics").sequenceTextStyle(.sectionHeader)
            LazyVGrid(columns: columns, spacing: SequenceSpacing.item) {
                metric("Completion 30d", "\(Int(s.completionRate30d))%")
                metric("Completion all-time", "\(Int(s.completionRateAllTime))%")
                metric("Best day", s.bestDayEver.formatted(.number.precision(.fractionLength(0...1))))
                metric("Lifetime total", s.totalLifetimeVolume.formatted(.number.precision(.fractionLength(0...0))))
                metric("Avg / active day", s.averageDailyCount.formatted(.number.precision(.fractionLength(0...1))))
                trendMetric(s.trend)
            }
        }
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: SequenceSpacing.half) {
            Text(value).sequenceTextStyle(.sectionHeader)
            Text(label).sequenceTextStyle(.subtext)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SequenceSpacing.cardPadding)
        .background(RoundedRectangle(cornerRadius: SequenceRadius.card, style: .continuous)
            .fill(SequenceColor.surfacePrimary))
    }

    private func trendMetric(_ trend: TrendDirection) -> some View {
        HStack(spacing: SequenceSpacing.item) {
            Image(systemName: trend.symbolName)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(SequenceColor.accentTeal)
            VStack(alignment: .leading, spacing: SequenceSpacing.half) {
                Text("14-day trend").sequenceTextStyle(.subtext)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SequenceSpacing.cardPadding)
        .background(RoundedRectangle(cornerRadius: SequenceRadius.card, style: .continuous)
            .fill(SequenceColor.surfacePrimary))
    }
}
