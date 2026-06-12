//
//  AuthManager.swift
//  Sequence
//
//  Sign in with Apple, local-only. There is no backend: the Apple user id is a
//  stable, non-secret identifier we persist and use to partition on-device data
//  (see SequenceRepository.ownerID) so multiple people can share one install
//  without seeing each other's habits. Reference: app_plan.md (auth).
//

import Foundation
import Observation
import AuthenticationServices

@Observable
final class AuthManager: NSObject {

    enum Status {
        /// Launch-time, before the stored credential has been revalidated.
        case unknown
        case signedOut
        case signedIn
    }

    private(set) var status: Status = .unknown
    private(set) var userID: String = ""
    private(set) var displayName: String = ""

    private enum Keys {
        static let userID = "sequence.auth.userID"
        static let displayName = "sequence.auth.displayName"
    }

    override init() {
        super.init()
        userID = UserDefaults.standard.string(forKey: Keys.userID) ?? ""
        displayName = UserDefaults.standard.string(forKey: Keys.displayName) ?? ""
        // Optimistic: trust the stored id so we don't flash the sign-in screen,
        // then confirm with Apple in `revalidate()`.
        status = userID.isEmpty ? .signedOut : .signedIn
    }

    /// Confirms the stored Apple credential is still valid (the user may have
    /// revoked access in Settings). Safe to call on every launch.
    func revalidate() async {
        guard !userID.isEmpty else {
            status = .signedOut
            return
        }
        let provider = ASAuthorizationAppleIDProvider()
        let credentialState = try? await provider.credentialState(forUserID: userID)
        switch credentialState {
        case .authorized:
            status = .signedIn
        case .revoked, .notFound:
            signOut()
        default:
            break // transient/unknown — keep the optimistic signed-in state
        }
    }

    /// Processes the result of a `SignInWithAppleButton`.
    func handle(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
            userID = credential.user
            UserDefaults.standard.set(credential.user, forKey: Keys.userID)
            // Full name is only delivered on the first authorization; persist it then.
            if let given = credential.fullName?.givenName, !given.isEmpty {
                displayName = given
                UserDefaults.standard.set(given, forKey: Keys.displayName)
            }
            status = .signedIn
        case .failure(let error):
            // User cancellation surfaces here too; nothing to persist.
            print("AuthManager: sign in failed — \(error.localizedDescription)")
        }
    }

    func signOut() {
        userID = ""
        displayName = ""
        UserDefaults.standard.removeObject(forKey: Keys.userID)
        UserDefaults.standard.removeObject(forKey: Keys.displayName)
        status = .signedOut
    }

    #if DEBUG
    /// Dev-only bypass. Sign in with Apple's XPC service frequently crashes in the
    /// iOS Simulator (EXC_GUARD / LIBXPC), so this lets us exercise the rest of the
    /// app there. Uses a fixed local id so partitioned data persists across launches.
    /// Compiled out of Release builds entirely.
    func signInForDevelopment() {
        userID = "DEV_LOCAL_USER"
        displayName = "Developer"
        UserDefaults.standard.set(userID, forKey: Keys.userID)
        UserDefaults.standard.set(displayName, forKey: Keys.displayName)
        status = .signedIn
    }
    #endif
}
