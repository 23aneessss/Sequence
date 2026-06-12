//
//  SettingsView.swift
//  Sequence
//
//  Tab 4 — preferences & customization. Reference: app_concept.md §8.1, §9.4.
//

import SwiftUI

struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(SequenceRepository.self) private var repo
    @Environment(NotificationManager.self) private var notifications
    @Environment(AuthManager.self) private var auth

    @State private var showPalette = false
    @State private var exportURL: URL?

    var body: some View {
        ZStack {
            SequenceColor.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: SequenceSpacing.section) {
                    Text("Settings").sequenceStyle(.appTitle)
                    appearanceSection(settings: settings)
                    notificationsSection(settings: settings)
                    graphSection(settings: settings)
                    streakSection(settings: settings)
                    reminderSection(settings: settings)
                    paletteAndData
                    about
                }
                .padding(SequenceSpacing.screenMargin)
            }
        }
        .sheet(isPresented: $showPalette) { PaletteManagerView() }
        .sheet(item: exportItemBinding) { item in ExportShareSheet(url: item.url) }
    }

    // MARK: - Sections

    private func appearanceSection(settings: SettingsStore) -> some View {
        card("Appearance") {
            Picker("Appearance", selection: Binding(get: { settings.appearance }, set: { settings.appearance = $0 })) {
                ForEach(AppAppearance.allCases) { Text($0.displayName).tag($0) }
            }
            .pickerStyle(.segmented)
        }
    }

    private func notificationsSection(settings: SettingsStore) -> some View {
        card("Notifications") {
            if notifications.authorizationStatus == .authorized {
                row("Status") { Text("On").sequenceTextStyle(.subtext).foregroundStyle(SequenceColor.mintTeal) }
                DatePicker("Morning task reminder",
                           selection: Binding(get: { settings.taskReminderTime }, set: { settings.taskReminderTime = $0 }),
                           displayedComponents: .hourAndMinute)
                    .sequenceTextStyle(.habitTitle)
                Toggle(isOn: Binding(get: { settings.dndEnabled }, set: { settings.dndEnabled = $0 })) {
                    Text("Quiet hours").sequenceTextStyle(.habitTitle)
                }.tint(SequenceColor.accentTeal)
                if settings.dndEnabled {
                    DatePicker("From", selection: Binding(get: { settings.dndStart }, set: { settings.dndStart = $0 }),
                               displayedComponents: .hourAndMinute).sequenceTextStyle(.subtext)
                    DatePicker("To", selection: Binding(get: { settings.dndEnd }, set: { settings.dndEnd = $0 }),
                               displayedComponents: .hourAndMinute).sequenceTextStyle(.subtext)
                }
            } else {
                Text("Streak-at-risk alerts keep your chain alive.").sequenceTextStyle(.subtext)
                PrimaryButton(title: "Enable reminders") {
                    Task {
                        await notifications.requestAuthorization()
                        await notifications.rescheduleAll()
                    }
                }
            }
        }
    }

    private func graphSection(settings: SettingsStore) -> some View {
        card("Graph") {
            row("Week starts on") {
                Picker("", selection: Binding(get: { settings.weekStartsOn }, set: { settings.weekStartsOn = $0 })) {
                    Text("Sunday").tag(1); Text("Monday").tag(2)
                }.pickerStyle(.menu).tint(SequenceColor.accentTeal)
            }
            row("Direction") {
                Picker("", selection: Binding(get: { settings.graphDirection }, set: { settings.graphDirection = $0 })) {
                    ForEach(GraphDirection.allCases) { Text($0.displayName).tag($0) }
                }.pickerStyle(.menu).tint(SequenceColor.accentTeal)
            }
        }
    }

    private func streakSection(settings: SettingsStore) -> some View {
        card("Streak threshold") {
            Stepper("Counts at level \(settings.streakMinLevel)+",
                    value: Binding(get: { settings.streakMinLevel }, set: { settings.streakMinLevel = $0 }), in: 1...5)
                .sequenceTextStyle(.habitTitle)
        }
    }

    private func reminderSection(settings: SettingsStore) -> some View {
        card("Default reminder") {
            DatePicker("Time", selection: Binding(get: { settings.defaultReminderTime },
                                                  set: { settings.defaultReminderTime = $0 }),
                       displayedComponents: .hourAndMinute)
                .sequenceTextStyle(.habitTitle)
        }
    }

    private var paletteAndData: some View {
        card("Customization & data") {
            Button { showPalette = true } label: { linkRow("Color palette", "paintpalette") }
            Button { exportURL = DataExporter.writeTempFile(habits: repo.allHabits(includeArchived: true),
                                                            tasks: repo.allTasks()) } label: {
                linkRow("Export data (JSON)", "square.and.arrow.up")
            }
            Button { UserDefaults.standard.set(false, forKey: "sequence.coachMarksSeen") } label: {
                linkRow("Reset coach marks", "arrow.counterclockwise")
            }
        }
    }

    private var about: some View {
        card("About") {
            row("Version") { Text("1.0").sequenceTextStyle(.subtext) }
            row("Made with") { Text("SwiftUI · SwiftData").sequenceTextStyle(.subtext) }
        }
    }

    // MARK: - Building blocks

    private func card<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: SequenceSpacing.item) {
            Text(title).sequenceTextStyle(.sectionHeader)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SequenceSpacing.cardPadding)
        .background(RoundedRectangle(cornerRadius: SequenceRadius.card, style: .continuous)
            .fill(SequenceColor.surfacePrimary))
    }

    private func row<Trailing: View>(_ label: String, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack { Text(label).sequenceTextStyle(.habitTitle); Spacer(); trailing() }
    }

    private func linkRow(_ label: String, _ icon: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(SequenceColor.accentTeal)
            Text(label).sequenceTextStyle(.habitTitle)
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(SequenceColor.textSecondary)
        }
        .foregroundStyle(SequenceColor.textPrimary)
    }

    private var exportItemBinding: Binding<ExportItem?> {
        Binding(get: { exportURL.map(ExportItem.init) }, set: { if $0 == nil { exportURL = nil } })
    }
}

private struct ExportItem: Identifiable { let url: URL; var id: String { url.path } }

private struct ExportShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
