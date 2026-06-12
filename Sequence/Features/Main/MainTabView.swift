//
//  MainTabView.swift
//  Sequence
//
//  The 4-tab application shell. Reference: app_concept.md §8.1.
//  Today (Phase 5) and Tasks (Phase 6) are live; Stats and Settings are
//  placeholders until Phases 7 and 8.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "square.grid.3x3.fill") }

            TasksView()
                .tabItem { Label("Tasks", systemImage: "checklist") }

            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(SequenceColor.accentTeal)
    }
}

/// Neutral placeholder for tabs whose phase hasn't landed yet.
struct ComingSoonView: View {
    let title: String
    let subtitle: String

    var body: some View {
        ZStack {
            SequenceColor.background.ignoresSafeArea()
            DashedEmptyState(title: title, message: subtitle)
                .padding(SequenceSpacing.screenMargin)
        }
    }
}
