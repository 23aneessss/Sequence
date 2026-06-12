//
//  SplashView.swift
//  Sequence
//
//  Launch splash. Reference: app_concept.md §7.1.
//  1.2s spring scale-up reveal, then dissolves into the next phase.
//

import SwiftUI

struct SplashView: View {
    var onFinish: () -> Void

    @State private var revealed = false

    var body: some View {
        ZStack {
            SequenceColor.background.ignoresSafeArea()
            VStack(spacing: SequenceSpacing.section) {
                SequenceLogo(size: 110)
                    .scaleEffect(revealed ? 1 : 0.7)
                    .opacity(revealed ? 1 : 0)
                Text("Sequence")
                    .sequenceStyle(.appTitle)
                    .opacity(revealed ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.sequenceStructural) { revealed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { onFinish() }
        }
    }
}
