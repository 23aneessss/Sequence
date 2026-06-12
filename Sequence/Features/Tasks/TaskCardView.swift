//
//  TaskCardView.swift
//  Sequence
//
//  A single task on the daily board. Reference: app_concept.md §4.3.
//

import SwiftUI

struct TaskCardView: View {
    let task: DailyTask
    var onToggle: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: SequenceSpacing.item) {
            SequenceCheckmarkButton(isCompleted: task.isCompleted, action: onToggle)

            VStack(alignment: .leading, spacing: SequenceSpacing.half) {
                Text(task.title)
                    .sequenceTextStyle(.habitTitle)
                    .strikethrough(task.isCompleted, color: SequenceColor.textSecondary)
                    .foregroundStyle(task.isCompleted ? SequenceColor.textSecondary : SequenceColor.textPrimary)
                if task.timeAnchor != nil || task.priority != .medium {
                    metaRow
                }
            }
            Spacer(minLength: 0)
        }
        .padding(SequenceSpacing.cardPadding)
        .background(RoundedRectangle(cornerRadius: SequenceRadius.card, style: .continuous)
            .fill(SequenceColor.surfacePrimary))
        .swipeActions { /* placeholder for List context; board uses long-press */ }
        .contextMenu {
            Button(role: .destructive, action: onDelete) { Label("Delete", systemImage: "trash") }
        }
    }

    private var metaRow: some View {
        HStack(spacing: SequenceSpacing.item) {
            if let anchor = task.timeAnchor {
                Label(anchor.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                    .sequenceTextStyle(.subtext)
            }
            priorityBadge
        }
    }

    @ViewBuilder private var priorityBadge: some View {
        if task.priority != .medium {
            Text(task.priority.displayName.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(SequenceColor.background)
                .padding(.horizontal, SequenceSpacing.item)
                .padding(.vertical, 2)
                .background(Capsule().fill(priorityColor))
        }
    }

    private var priorityColor: Color {
        switch task.priority {
        case .high:   return Color(hex: "E05C5C")
        case .medium: return SequenceColor.accentTeal
        case .low:    return SequenceColor.textSecondary
        }
    }
}
