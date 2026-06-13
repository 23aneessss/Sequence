//
//  SplashView.swift
//  Sequence
//
//  Launch splash. Reference: app_concept.md §7.1.
//  The mark builds itself square-by-square, then the wordmark fades in, then
//  the splash dissolves into the next phase.
//

import SwiftUI

struct SplashView: View {
    var onFinish: () -> Void

    @State private var titleShown = false

    var body: some View {
        ZStack {
            SequenceColor.background.ignoresSafeArea()
            VStack(spacing: SequenceSpacing.section) {
                SequenceLogo(size: 110, animated: true)
                Text("Sequence")
                    .sequenceStyle(.appTitle)
                    .opacity(titleShown ? 1 : 0)
                    .offset(y: titleShown ? 0 : 10)
            }
        }
        .onAppear {
            // Let the 16 cells finish building (~0.9s), then reveal the wordmark.
            withAnimation(.sequenceFluid.delay(0.9)) { titleShown = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { onFinish() }
        }
    }
}
