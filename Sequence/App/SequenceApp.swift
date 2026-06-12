//
//  SequenceApp.swift
//  Sequence
//
//  App entry point. Owns the SwiftData container and the shared stores/managers,
//  injecting them into the environment for all feature views.
//

import SwiftUI
import SwiftData

@main
struct SequenceApp: App {
    @Environment(\.scenePhase) private var scenePhase

    private let container: ModelContainer
    private let backgroundTasks = BackgroundTaskManager()
    @State private var repository: SequenceRepository
    @State private var timerManager = HabitTimerManager()
    @State private var settings = SettingsStore()
    @State private var palette = PaletteStore()
    @State private var notifications = NotificationManager()

    init() {
        do {
            let container = try SequenceModelContainer.live()
            self.container = container
            let repository = SequenceRepository(modelContext: container.mainContext)
            DemoSeeder.seedIfRequested(into: repository)
            _repository = State(initialValue: repository)

            // Background task registration must occur before launch completes.
            backgroundTasks.register(notifications: notifications, repo: repository)
        } catch {
            // Container creation is app infrastructure; failure here is unrecoverable
            // and indicates a schema/migration fault, not user data we can fall back on.
            fatalError("Sequence: failed to initialize persistence: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(repository)
                .environment(timerManager)
                .environment(settings)
                .environment(palette)
                .environment(notifications)
                .preferredColorScheme(settings.appearance.colorScheme)
                .task { notifications.configure(repo: repository, settings: settings) }
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                Task { await notifications.rescheduleAll() }
            case .background:
                backgroundTasks.scheduleNextRefresh()
            default:
                break
            }
        }
    }
}
