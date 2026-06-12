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

/// Launch phases. Reference: app_concept.md §7.1, §8.1.
private enum LaunchPhase { case splash, auth, onboarding, main }

/// The single root view installed by `SequenceApp`.
struct RootView: View {
    @Environment(SequenceRepository.self) private var repo
    @Environment(AuthManager.self) private var auth
    @State private var router = AppRouter()
    @State private var phase: LaunchPhase = .splash
    @Namespace private var debugNamespace

    var body: some View {
        // SEQ_SCREEN env var routes directly to a screen for screenshot
        // verification (paired with SEQ_SEED). Normal launches ignore it.
        if ProcessInfo.processInfo.environment["SEQ_SCREEN"] != nil {
            debugScreen
        } else {
            orchestrated
                .onChange(of: auth.status) { _, status in
                    // Sign-out from Settings drops us back to the gate.
                    if status == .signedOut {
                        repo.setOwner("")
                        withAnimation(.sequenceStructural) { phase = .auth }
                    }
                }
        }
    }

    @ViewBuilder private var orchestrated: some View {
        switch phase {
        case .splash:
            SplashView {
                withAnimation(.sequenceFluid) { phase = postSplashPhase() }
            }
            .transition(.opacity)
        case .auth:
            AuthView {
                repo.setOwner(auth.userID)
                withAnimation(.sequenceStructural) { phase = router.hasOnboarded ? .main : .onboarding }
            }
            .transition(.opacity)
        case .onboarding:
            OnboardingView {
                router.hasOnboarded = true
                withAnimation(.sequenceStructural) { phase = .main }
            }
            .transition(.opacity)
        case .main:
            MainTabView()
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
        }
    }

    /// Where to go once the splash finishes: gate on auth first, then onboarding.
    private func postSplashPhase() -> LaunchPhase {
        guard auth.status == .signedIn else { return .auth }
        repo.setOwner(auth.userID)
        return router.hasOnboarded ? .main : .onboarding
    }

    @ViewBuilder private var debugScreen: some View {
        switch ProcessInfo.processInfo.environment["SEQ_SCREEN"] {
        case "main", "today": MainTabView()
        case "create":   HabitCreationSheet()
        case "detail":
            if let habit = repo.habits.first(where: { $0.type == .counted }) ?? repo.habits.first {
                HabitDetailView(habit: habit, namespace: debugNamespace) {}
            }
        case "tasks":    TasksView()
        case "stats":    StatsView()
        case "settings": SettingsView()
        case "palette":  PaletteManagerView()
        case "yearly":   YearlyReviewView(habits: repo.habits)
        case "onboarding": OnboardingView {}
        default: EmptyView()
        }
    }
}

#Preview {
    RootView()
}
