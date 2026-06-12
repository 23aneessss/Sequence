//
//  TasksView.swift
//  Sequence
//
//  Tab 2 — the daily commitment board. Reference: app_concept.md §4, §8.1, §11.4.
//

import SwiftUI

struct TasksView: View {
    @Environment(SequenceRepository.self) private var repo

    @State private var showAdd = false
    @State private var perfectDay = false
    @State private var rolloverDismissed = false

    private let calendar = Calendar.sequence
    private var today: Date { Date.now.normalizedDay(calendar) }
    private var yesterday: Date { calendar.date(byAdding: .day, value: -1, to: today) ?? today }

    private var todayTasks: [DailyTask] { repo.tasks(on: today) }
    private var completedCount: Int { todayTasks.filter(\.isCompleted).count }
    private var isPerfect: Bool { !todayTasks.isEmpty && completedCount == todayTasks.count }

    var body: some View {
        let _ = repo.taskRevision // establish dependency: re-render on any task change
        ZStack(alignment: .top) {
            SequenceColor.background.ignoresSafeArea()
            content
            fab
            if perfectDay { perfectBanner.transition(.move(edge: .top).combined(with: .opacity)) }
        }
        .sheet(isPresented: $showAdd) {
            AddTaskSheet(day: today).presentationDetents([.fraction(0.5), .large])
        }
        .onChange(of: completedCount) { _, _ in handlePerfectDay() }
    }

    // MARK: - Content

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SequenceSpacing.section) {
                header
                if !rolloverDismissed, !repo.tasks(on: yesterday).filter({ !$0.isCompleted }).isEmpty {
                    rolloverPrompt
                }
                if !repo.templateTasks().isEmpty { templatesStrip }
                board
                graphSection
            }
            .padding(SequenceSpacing.screenMargin)
            .padding(.bottom, 80)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: SequenceSpacing.item) {
            VStack(alignment: .leading, spacing: SequenceSpacing.half) {
                Text("Tasks").sequenceStyle(.appTitle)
                Text(today.formatted(.dateTime.weekday(.wide).month().day())).sequenceTextStyle(.subtext)
            }
            if !todayTasks.isEmpty { progressBar }
        }
    }

    private var progressBar: some View {
        let fraction = todayTasks.isEmpty ? 0 : Double(completedCount) / Double(todayTasks.count)
        return VStack(alignment: .leading, spacing: SequenceSpacing.half) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(SequenceColor.surfaceSecondary)
                    Capsule().fill(SequenceColor.accentTeal).frame(width: geo.size.width * fraction)
                }
            }
            .frame(height: 8)
            Text("\(completedCount) of \(todayTasks.count) complete").sequenceTextStyle(.subtext)
        }
    }

    @ViewBuilder private var board: some View {
        if todayTasks.isEmpty {
            DashedEmptyState(title: "No tasks set yet", message: "What will you accomplish today?")
        } else {
            LazyVStack(spacing: SequenceSpacing.item) {
                ForEach(todayTasks, id: \.id) { task in
                    TaskCardView(task: task,
                                 onToggle: { repo.toggleTask(task) },
                                 onDelete: { repo.deleteTask(task) })
                }
            }
        }
    }

    private var graphSection: some View {
        VStack(alignment: .leading, spacing: SequenceSpacing.item) {
            Text("Task Graph").sequenceTextStyle(.sectionHeader)
            TaskContributionGraphView(completionRates: repo.taskCompletionRates())
            Text("Each square is a day. A full square is a Perfect Day.").sequenceTextStyle(.subtext)
        }
    }

    // MARK: - Templates & rollover

    private var templatesStrip: some View {
        VStack(alignment: .leading, spacing: SequenceSpacing.item) {
            Text("Templates").sequenceTextStyle(.sectionHeader)
            FlowChips(items: repo.templateTasks().map(\.title)) { title in
                repo.createTask(title: title, on: today)
            }
        }
    }

    private var rolloverPrompt: some View {
        let incomplete = repo.tasks(on: yesterday).filter { !$0.isCompleted }
        return HStack(spacing: SequenceSpacing.item) {
            VStack(alignment: .leading, spacing: SequenceSpacing.half) {
                Text("Roll over \(incomplete.count) unfinished").sequenceTextStyle(.habitTitle)
                Text("From yesterday").sequenceTextStyle(.subtext)
            }
            Spacer()
            Button("Roll over") {
                repo.rollOverIncompleteTasks(from: yesterday)
                withAnimation(.sequenceFluid) { rolloverDismissed = true }
            }
            .sequenceTextStyle(.habitTitle)
            .foregroundStyle(SequenceColor.accentTeal)
            Button { withAnimation { rolloverDismissed = true } } label: {
                Image(systemName: "xmark").foregroundStyle(SequenceColor.textSecondary)
            }
        }
        .padding(SequenceSpacing.cardPadding)
        .background(RoundedRectangle(cornerRadius: SequenceRadius.card, style: .continuous)
            .fill(SequenceColor.surfacePrimary))
    }

    // MARK: - FAB & Perfect Day

    private var fab: some View {
        VStack { Spacer(); HStack { Spacer()
            Button { showAdd = true } label: {
                Image(systemName: "plus").font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(SequenceColor.background)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(SequenceColor.accentTeal))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            }
            .buttonStyle(SequencePressStyle())
            .padding(SequenceSpacing.screenMargin)
        } }
    }

    private var perfectBanner: some View {
        Text("Perfect day. All tasks complete.")
            .sequenceTextStyle(.habitTitle)
            .foregroundStyle(SequenceColor.background)
            .padding(SequenceSpacing.cardPadding)
            .frame(maxWidth: .infinity)
            .background(SequenceColor.accentTeal)
            .padding(.horizontal, SequenceSpacing.screenMargin)
    }

    private func handlePerfectDay() {
        guard isPerfect else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.sequenceFluid) { perfectDay = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.sequenceFluid) { perfectDay = false }
        }
    }
}

/// Simple wrapping chip row for template suggestions.
private struct FlowChips: View {
    let items: [String]
    let onTap: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SequenceSpacing.item) {
                ForEach(items, id: \.self) { item in
                    Button { onTap(item) } label: {
                        HStack(spacing: SequenceSpacing.half) {
                            Image(systemName: "plus.circle").font(.system(size: 12))
                            Text(item).sequenceTextStyle(.subtext)
                        }
                        .foregroundStyle(SequenceColor.textSecondary)
                        .padding(.horizontal, SequenceSpacing.cardPadding)
                        .padding(.vertical, SequenceSpacing.item)
                        .background(Capsule().strokeBorder(SequenceColor.borderOpaque,
                                                           style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
                    }
                    .buttonStyle(SequencePressStyle())
                }
            }
        }
    }
}
