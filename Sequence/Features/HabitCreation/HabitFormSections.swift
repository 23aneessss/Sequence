//
//  HabitFormSections.swift
//  Sequence
//
//  Focused subviews for the habit creation form. Reference: app_concept.md §3.3.
//

import SwiftUI

// MARK: - Shared section chrome

private struct SectionLabel: View {
    let text: String
    var body: some View { Text(text).sequenceTextStyle(.sectionHeader) }
}

// MARK: - Name & Icon

struct HabitNameIconSection: View {
    @Bindable var form: HabitFormModel
    private let columns = [GridItem(.adaptive(minimum: 44), spacing: SequenceSpacing.item)]

    var body: some View {
        VStack(alignment: .leading, spacing: SequenceSpacing.item) {
            SectionLabel(text: "Name & icon")
            TextField("Habit name", text: $form.name)
                .sequenceTextStyle(.habitTitle)
                .padding(SequenceSpacing.cardPadding)
                .background(RoundedRectangle(cornerRadius: SequenceRadius.small, style: .continuous)
                    .fill(SequenceColor.surfaceSecondary))

            LazyVGrid(columns: columns, spacing: SequenceSpacing.item) {
                ForEach(HabitFormModel.iconChoices, id: \.self) { symbol in
                    Button { form.icon = symbol } label: {
                        Image(systemName: symbol)
                            .font(.system(size: 18))
                            .foregroundStyle(form.icon == symbol ? SequenceColor.background : SequenceColor.textPrimary)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(form.icon == symbol ? SequenceColor.accentTeal : SequenceColor.surfaceSecondary))
                    }
                    .buttonStyle(SequencePressStyle())
                }
            }
        }
    }
}

// MARK: - Type

struct HabitTypeSection: View {
    @Bindable var form: HabitFormModel

    var body: some View {
        VStack(alignment: .leading, spacing: SequenceSpacing.item) {
            SectionLabel(text: "Type")
            HStack(spacing: SequenceSpacing.item) {
                ForEach(HabitType.allCases) { type in
                    Button { withAnimation(.sequenceFluid) { form.type = type } } label: {
                        Text(type.displayName)
                            .sequenceTextStyle(.habitTitle)
                            .foregroundStyle(form.type == type ? SequenceColor.background : SequenceColor.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, SequenceSpacing.item + 2)
                            .background(RoundedRectangle(cornerRadius: SequenceRadius.small, style: .continuous)
                                .fill(form.type == type ? SequenceColor.accentTeal : SequenceColor.surfaceSecondary))
                    }
                    .buttonStyle(SequencePressStyle())
                }
            }
        }
    }
}

// MARK: - Color

struct HabitColorSection: View {
    @Bindable var form: HabitFormModel

    var body: some View {
        VStack(alignment: .leading, spacing: SequenceSpacing.item) {
            SectionLabel(text: "Color")
            HStack(spacing: SequenceSpacing.item) {
                ForEach(DefaultPalette.swatches) { swatch in
                    Button { form.colorHex = swatch.hex } label: {
                        Circle()
                            .fill(Color(hex: swatch.hex))
                            .frame(width: 36, height: 36)
                            .overlay(Circle().strokeBorder(SequenceColor.textPrimary,
                                                           lineWidth: form.colorHex == swatch.hex ? 3 : 0))
                    }
                    .buttonStyle(SequencePressStyle())
                }
            }
        }
    }
}

// MARK: - Target (counted/timed)

struct HabitTargetSection: View {
    @Bindable var form: HabitFormModel

    private var unitWord: String { form.type == .timed ? "minutes" : "units" }

    var body: some View {
        VStack(alignment: .leading, spacing: SequenceSpacing.item) {
            SectionLabel(text: "Target")
            if form.type == .counted {
                TextField("Unit (reps, glasses…)", text: $form.unit)
                    .sequenceTextStyle(.habitTitle)
                    .padding(SequenceSpacing.cardPadding)
                    .background(RoundedRectangle(cornerRadius: SequenceRadius.small, style: .continuous)
                        .fill(SequenceColor.surfaceSecondary))
            }
            numberRow(label: "Daily target (\(unitWord))", value: $form.dailyTarget)
            numberRow(label: "Overachieve target", value: $form.overachieveTarget)
        }
    }

    private func numberRow(label: String, value: Binding<Double>) -> some View {
        HStack {
            Text(label).sequenceTextStyle(.habitTitle)
            Spacer()
            TextField("0", value: value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .sequenceTextStyle(.habitTitle)
                .frame(width: 80)
                .padding(.vertical, SequenceSpacing.half)
                .padding(.horizontal, SequenceSpacing.item)
                .background(RoundedRectangle(cornerRadius: SequenceRadius.small, style: .continuous)
                    .fill(SequenceColor.surfaceSecondary))
        }
    }
}

// MARK: - Schedule

struct HabitScheduleSection: View {
    @Bindable var form: HabitFormModel
    private let weekdaySymbols = Calendar.sequence.shortWeekdaySymbols

    var body: some View {
        VStack(alignment: .leading, spacing: SequenceSpacing.item) {
            SectionLabel(text: "Schedule")
            Picker("Schedule", selection: $form.scheduleKind) {
                Text("Daily").tag(HabitFormModel.ScheduleKind.daily)
                Text("Weekdays").tag(HabitFormModel.ScheduleKind.weekdays)
                Text("Every N days").tag(HabitFormModel.ScheduleKind.everyN)
            }
            .pickerStyle(.segmented)

            switch form.scheduleKind {
            case .daily:
                EmptyView()
            case .weekdays:
                weekdayChips
            case .everyN:
                Stepper("Every \(form.everyNDays) days", value: $form.everyNDays, in: 1...30)
                    .sequenceTextStyle(.habitTitle)
            }
        }
    }

    private var weekdayChips: some View {
        HStack(spacing: SequenceSpacing.half) {
            ForEach(1...7, id: \.self) { weekday in
                let on = form.selectedWeekdays.contains(weekday)
                Button {
                    if on { form.selectedWeekdays.remove(weekday) } else { form.selectedWeekdays.insert(weekday) }
                } label: {
                    Text(String(weekdaySymbols[weekday - 1].prefix(1)))
                        .sequenceTextStyle(.subtext)
                        .foregroundStyle(on ? SequenceColor.background : SequenceColor.textPrimary)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(on ? SequenceColor.accentTeal : SequenceColor.surfaceSecondary))
                }
                .buttonStyle(SequencePressStyle())
            }
        }
    }
}

// MARK: - Reminder

struct HabitReminderSection: View {
    @Bindable var form: HabitFormModel

    var body: some View {
        VStack(alignment: .leading, spacing: SequenceSpacing.item) {
            Toggle(isOn: $form.reminderOn) {
                Text("Reminder").sequenceTextStyle(.sectionHeader)
            }
            .tint(SequenceColor.accentTeal)

            if form.reminderOn {
                DatePicker("Time", selection: $form.reminderTime, displayedComponents: .hourAndMinute)
                    .sequenceTextStyle(.habitTitle)
            }
        }
    }
}
