//
//  AuthView.swift
//  Sequence
//
//  The sign-in gate. Sign in with Apple is the primary option; a local name
//  profile is offered below as a no-account fallback (and the working path on a
//  free developer account). Reference: app_plan.md (auth).
//

import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var nameFocused: Bool
    @State private var name = ""
    var onSignedIn: () -> Void

    private var canContinue: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: SequenceSpacing.section) {
            Spacer()
            SequenceLogo(size: 104, animated: true)
            VStack(spacing: SequenceSpacing.item) {
                Text("Welcome to Sequence")
                    .sequenceTextStyle(.greeting)
                    .multilineTextAlignment(.center)
                Text("Sign in to keep your streaks yours — your habits stay private to your profile.")
                    .sequenceTextStyle(.subtext)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, SequenceSpacing.section)
            }
            Spacer()
            signInOptions
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SequenceColor.background.ignoresSafeArea())
    }

    private var signInOptions: some View {
        VStack(spacing: SequenceSpacing.item) {
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName]
            } onCompletion: { result in
                auth.handleApple(result)
                if auth.status == .signedIn { onSignedIn() }
            }
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: SequenceRadius.small, style: .continuous))

            dividerOr

            HStack(spacing: SequenceSpacing.item) {
                TextField("Your name", text: $name)
                    .focused($nameFocused)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.go)
                    .onSubmit(continueWithName)
                    .sequenceTextStyle(.habitTitle)
                    .padding(SequenceSpacing.cardPadding)
                    .background(RoundedRectangle(cornerRadius: SequenceRadius.small, style: .continuous)
                        .fill(SequenceColor.surfaceSecondary))
                Button(action: continueWithName) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(SequenceColor.background)
                        .frame(width: 52, height: 52)
                        .background(RoundedRectangle(cornerRadius: SequenceRadius.small, style: .continuous)
                            .fill(SequenceColor.accentTeal))
                }
                .buttonStyle(SequencePressStyle())
                .opacity(canContinue ? 1 : 0.4)
                .disabled(!canContinue)
            }
        }
        .padding(.horizontal, SequenceSpacing.screenMargin)
        .padding(.bottom, SequenceSpacing.section)
    }

    private var dividerOr: some View {
        HStack(spacing: SequenceSpacing.item) {
            Rectangle().fill(SequenceColor.surfaceSecondary).frame(height: 1)
            Text("or").sequenceTextStyle(.subtext)
            Rectangle().fill(SequenceColor.surfaceSecondary).frame(height: 1)
        }
    }

    private func continueWithName() {
        guard canContinue else { return }
        auth.signIn(name: name)
        if auth.status == .signedIn { onSignedIn() }
    }
}
