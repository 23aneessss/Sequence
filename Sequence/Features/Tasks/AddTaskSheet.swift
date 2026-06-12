//
//  AddTaskSheet.swift
//  Sequence
//
//  Add a task to today's board. Reference: app_concept.md §4.3, §8.2 (.fraction(0.4)).
//

import SwiftUI

struct AddTaskSheet: View {
    let day: Date
    @Environment(SequenceRepository.self) private var repo
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var priority: TaskPriority = .medium
    @State private var hasTime = false
    @State private var time = Date.now
    @State private var saveAsTemplate = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SequenceSpacing.section) {
                Text("New task").sequenceTextStyle(.sectionHeader)

                TextField("What will you accomplish?", text: $title)
                    .sequenceTextStyle(.habitTitle)
                    .padding(SequenceSpacing.cardPadding)
                    .background(RoundedRectangle(cornerRadius: SequenceRadius.small, style: .continuous)
                        .fill(SequenceColor.surfaceSecondary))

                priorityPicker

                Toggle(isOn: $hasTime) { Text("Time anchor").sequenceTextStyle(.habitTitle) }
                    .tint(SequenceColor.accentTeal)
                if hasTime {
                    DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                        .sequenceTextStyle(.habitTitle)
                }

                Toggle(isOn: $saveAsTemplate) { Text("Save as daily template").sequenceTextStyle(.habitTitle) }
                    .tint(SequenceColor.accentTeal)

                PrimaryButton(title: "Add task", isEnabled: !title.trimmingCharacters(in: .whitespaces).isEmpty) {
                    repo.createTask(title: title.trimmingCharacters(in: .whitespaces), on: day,
                                    priority: priority, timeAnchor: hasTime ? time : nil,
                                    isTemplate: saveAsTemplate)
                    dismiss()
                }
            }
            .padding(SequenceSpacing.screenMargin)
        }
        .background(SequenceColor.background.ignoresSafeArea())
    }

    private var priorityPicker: some View {
        HStack(spacing: SequenceSpacing.item) {
            ForEach(TaskPriority.allCases) { p in
                Button { priority = p } label: {
                    Text(p.displayName)
                        .sequenceTextStyle(.subtext)
                        .foregroundStyle(priority == p ? SequenceColor.background : SequenceColor.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, SequenceSpacing.item)
                        .background(RoundedRectangle(cornerRadius: SequenceRadius.small, style: .continuous)
                            .fill(priority == p ? SequenceColor.accentTeal : SequenceColor.surfaceSecondary))
                }
                .buttonStyle(SequencePressStyle())
            }
        }
    }
}
