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
    var body: some View {
        // Phase 1 scaffold: surfaces the Design System so the foundation is
        // verifiable on a real simulator. Replaced by AppRouter-driven routing
        // once Onboarding (Phase 10) and the Main tab bar (Phase 5) exist.
        DesignSystemPreview()
    }
}

#Preview {
    RootView()
}
