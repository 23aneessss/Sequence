//
//  SequenceApp.swift
//  Sequence
//
//  App entry point. SwiftData container wiring arrives in Phase 2 (Data Layer);
//  this stage establishes the launch surface and root routing.
//

import SwiftUI

@main
struct SequenceApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
