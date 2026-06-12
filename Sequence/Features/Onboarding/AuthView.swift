//
//  AuthView.swift
//  Sequence
//
//  The sign-in gate shown before onboarding/main when no account is active.
//  Sign in with Apple only — local, no backend. Reference: app_plan.md (auth).
//

import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(\.colorScheme) private var colorScheme
    var onSignedIn: () -> Void

    var body: some View {
        VStack(spacing: SequenceSpacing.section) {
            Spacer()
            SequenceLogo(size: 120)
            VStack(spacing: SequenceSpacing.item) {
                Text("Welcome to Sequence")
                    .sequenceTextStyle(.appTitle)
                    .multilineTextAlignment(.center)
                Text("Sign in to keep your streaks yours — your habits stay private to your account on this device.")
                    .sequenceTextStyle(.subtext)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, SequenceSpacing.section)
            }
            Spacer()
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName]
            } onCompletion: { result in
                auth.handle(result)
                if auth.status == .signedIn { onSignedIn() }
            }
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: SequenceRadius.small, style: .continuous))
            .padding(.horizontal, SequenceSpacing.screenMargin)
            .padding(.bottom, SequenceSpacing.section)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SequenceColor.background.ignoresSafeArea())
    }
}
