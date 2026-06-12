//
//  CoachMarkOverlay.swift
//  Sequence
//
//  First-session guidance. Reference: app_concept.md §7.3.
//  Four sequential marks, each dismissed by a tap; shown once then gated by
//  UserDefaults (resettable from Settings).
//

import SwiftUI

struct CoachMark {
    let text: String
    let alignment: Alignment
    let arrow: String
}

struct CoachMarkOverlay: View {
    @Binding var isPresented: Bool
    @State private var step = 0

    private let marks: [CoachMark] = [
        CoachMark(text: "Tap here to log your habit", alignment: .top, arrow: "arrow.up"),
        CoachMark(text: "This is your last 7 days", alignment: .top, arrow: "arrow.up"),
        CoachMark(text: "Track your momentum here", alignment: .bottom, arrow: "arrow.down"),
        CoachMark(text: "Add more habits here", alignment: .bottomTrailing, arrow: "arrow.down.right")
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture(perform: advance)

            callout
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: marks[step].alignment)
                .padding(SequenceSpacing.section)
                .padding(.top, marks[step].alignment == .top ? 80 : 0)
                .padding(.bottom, marks[step].alignment != .top ? 80 : 0)
        }
        .transition(.opacity)
    }

    private var callout: some View {
        VStack(spacing: SequenceSpacing.item) {
            if marks[step].alignment != .top {
                Image(systemName: marks[step].arrow).foregroundStyle(SequenceColor.background)
            }
            VStack(spacing: SequenceSpacing.item) {
                Text(marks[step].text)
                    .sequenceTextStyle(.habitTitle)
                    .foregroundStyle(SequenceColor.background)
                    .multilineTextAlignment(.center)
                Text("\(step + 1) of \(marks.count) · tap to continue")
                    .font(.system(size: 11))
                    .foregroundStyle(SequenceColor.background.opacity(0.7))
            }
            .padding(SequenceSpacing.cardPadding)
            .background(RoundedRectangle(cornerRadius: SequenceRadius.card, style: .continuous)
                .fill(SequenceColor.accentTeal))
            if marks[step].alignment == .top {
                Image(systemName: marks[step].arrow).foregroundStyle(SequenceColor.background)
            }
        }
    }

    private func advance() {
        if step < marks.count - 1 {
            withAnimation(.sequenceFluid) { step += 1 }
        } else {
            withAnimation(.sequenceFluid) { isPresented = false }
        }
    }
}
