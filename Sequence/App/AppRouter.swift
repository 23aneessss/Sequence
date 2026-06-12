//
//  AppRouter.swift
//  Sequence
//
//  Top-level launch routing: splash → onboarding (first launch) → main app.
//  Reference: app_concept.md §7.1 / §8.1.
//
//  Each destination is filled in by its phase:
//    • .onboarding  → Phase 10 (Onboarding)
//    • .main        → Phase 5 (Today dashboard + tab bar)
//  Until those land, the router resolves to the Design System preview so the
//  Phase 1 foundation is runnable and inspectable on device.
//

import SwiftUI

/// The top-level destinations the app can resolve to at launch.
enum AppDestination {
    case onboarding
    case main
}

/// Resolves which destination to show based on persisted launch state.
@Observable
final class AppRouter {

    private enum Keys {
        static let hasOnboarded = "sequence.hasOnboarded"
    }

    /// Whether the user has completed onboarding (set true at the end of Phase 10 flow).
    var hasOnboarded: Bool {
        didSet { UserDefaults.standard.set(hasOnboarded, forKey: Keys.hasOnboarded) }
    }

    init() {
        self.hasOnboarded = UserDefaults.standard.bool(forKey: Keys.hasOnboarded)
    }

    var destination: AppDestination {
        hasOnboarded ? .main : .onboarding
    }
}

/// The single root view installed by `SequenceApp`.
struct RootView: View {
    @Environment(SequenceRepository.self) private var repo
    @Namespace private var debugNamespace

    var body: some View {
        // The main app shell. Onboarding (Phase 10) will wrap this via AppRouter
        // once it exists; for now we route straight to the tab bar.
        //
        // SEQ_SCREEN env var routes directly to a screen for screenshot
        // verification (paired with SEQ_SEED). Normal launches ignore it.
        switch ProcessInfo.processInfo.environment["SEQ_SCREEN"] {
        case "create":
            HabitCreationSheet()
        case "detail":
            if let habit = repo.habits.first(where: { $0.type == .counted }) ?? repo.habits.first {
                HabitDetailView(habit: habit, namespace: debugNamespace) {}
            } else {
                MainTabView()
            }
        case "tasks":
            TasksView()
        case "stats":
            StatsView()
        case "settings":
            SettingsView()
        case "palette":
            PaletteManagerView()
        case "yearly":
            YearlyReviewView(habits: repo.habits)
        default:
            MainTabView()
        }
    }
}

#Preview {
    RootView()
}
