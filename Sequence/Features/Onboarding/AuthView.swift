//
//  AuthView.swift
//  Sequence
//
//  The local profile gate shown before onboarding/main. The user types a name;
//  no Apple account or backend involved. Reference: app_plan.md (auth).
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
            SequenceLogo(size: 120)
            VStack(spacing: SequenceSpacing.item) {
                Text("Welcome to Sequence")
                    .sequenceTextStyle(.greeting)
                    .multilineTextAlignment(.center)
                Text("What should we call you? Your habits stay private to your profile on this device.")
                    .sequenceTextStyle(.subtext)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, SequenceSpacing.section)
            }
            TextField("Your name", text: $name)
                .focused($nameFocused)
                .textInputAutocapitalization(.words)
                .submitLabel(.go)
                .onSubmit(signIn)
                .multilineTextAlignment(.center)
                .sequenceTextStyle(.habitTitle)
                .padding(SequenceSpacing.cardPadding)
                .background(RoundedRectangle(cornerRadius: SequenceRadius.small, style: .continuous)
                    .fill(SequenceColor.surfaceSecondary))
                .padding(.horizontal, SequenceSpacing.screenMargin)
            Spacer()
            PrimaryButton(title: "Continue", action: signIn)
                .opacity(canContinue ? 1 : 0.45)
                .disabled(!canContinue)
                .padding(.horizontal, SequenceSpacing.screenMargin)
                .padding(.bottom, SequenceSpacing.section)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SequenceColor.background.ignoresSafeArea())
        .onAppear { nameFocused = true }
    }

    private func signIn() {
        guard canContinue else { return }
        auth.signIn(name: name)
        if auth.status == .signedIn { onSignedIn() }
    }
}
