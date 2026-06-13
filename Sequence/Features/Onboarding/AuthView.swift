//
//  AuthView.swift
//  Sequence
//
//  The sign-in gate: a local name profile (no Apple account, no backend).
//  Each name keeps its own private habits on this device. Reference: app_plan.md.
//

import SwiftUI

struct AuthView: View {
    @Environment(AuthManager.self) private var auth
    @FocusState private var nameFocused: Bool
    @State private var name = ""
    var onSignedIn: () -> Void

    private var canContinue: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: SequenceSpacing.section) {
            Spacer()
            SequenceLogo(size: 110, animated: true)
            VStack(spacing: SequenceSpacing.item) {
                Text("Welcome to Sequence")
                    .sequenceTextStyle(.greeting)
                    .multilineTextAlignment(.center)
                Text("What should we call you? Your habits stay private to your profile on this device.")
                    .sequenceTextStyle(.subtext)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, SequenceSpacing.section)
            }
            Spacer()
            VStack(spacing: SequenceSpacing.item) {
                TextField("Your name", text: $name)
                    .focused($nameFocused)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.go)
                    .onSubmit(continueWithName)
                    .multilineTextAlignment(.center)
                    .sequenceTextStyle(.habitTitle)
                    .padding(SequenceSpacing.cardPadding)
                    .background(RoundedRectangle(cornerRadius: SequenceRadius.small, style: .continuous)
                        .fill(SequenceColor.surfaceSecondary))
                PrimaryButton(title: "Continue", action: continueWithName)
                    .opacity(canContinue ? 1 : 0.45)
                    .disabled(!canContinue)
            }
            .padding(.horizontal, SequenceSpacing.screenMargin)
            .padding(.bottom, SequenceSpacing.section)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SequenceColor.background.ignoresSafeArea())
        .onAppear { nameFocused = true }
    }

    private func continueWithName() {
        guard canContinue else { return }
        auth.signIn(name: name)
        if auth.status == .signedIn { onSignedIn() }
    }
}
