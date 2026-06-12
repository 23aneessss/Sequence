//
//  SequenceApp.swift
//  Sequence
//
//  App entry point. Owns the SwiftData container and the SequenceRepository,
//  injecting the latter into the environment for all feature views.
//

import SwiftUI
import SwiftData

@main
struct SequenceApp: App {
    private let container: ModelContainer
    @State private var repository: SequenceRepository
    @State private var timerManager = HabitTimerManager()
    @State private var settings = SettingsStore()
    @State private var palette = PaletteStore()

    init() {
        do {
            let container = try SequenceModelContainer.live()
            self.container = container
            let repository = SequenceRepository(modelContext: container.mainContext)
            DemoSeeder.seedIfRequested(into: repository)
            _repository = State(initialValue: repository)
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
                .preferredColorScheme(settings.appearance.colorScheme)
        }
        .modelContainer(container)
    }
}
