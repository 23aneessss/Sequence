//
//  AuthManager.swift
//  Sequence
//
//  Local profile sign-in — no Apple account, no backend. The user enters a name;
//  each distinct name becomes its own private profile via the derived owner id
//  (see SequenceRepository.ownerID), so several people can share one install
//  without seeing each other's habits. The name also personalizes the UI.
//

import Foundation
import Observation
import AuthenticationServices

@Observable
final class AuthManager {

    enum Status {
        /// Launch-time, before the stored profile has been read.
        case unknown
        case signedOut
        case signedIn
    }

    private(set) var status: Status = .unknown
    /// Stable per-profile id used to partition data. Empty when signed out.
    private(set) var userID: String = ""
    /// The name the user typed — shown across the app ("Good morning, Aness").
    private(set) var displayName: String = ""

    private enum Keys {
        static let userID = "sequence.auth.userID"
        static let displayName = "sequence.auth.displayName"
    }

    init() {
        userID = UserDefaults.standard.string(forKey: Keys.userID) ?? ""
        displayName = UserDefaults.standard.string(forKey: Keys.displayName) ?? ""
        status = userID.isEmpty ? .signedOut : .signedIn
    }

    /// Signs in (or switches to) a local profile identified by `name`. Returning
    /// with the same name reuses that profile's data; a new name starts fresh.
    func signIn(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        displayName = trimmed
        userID = "local:" + Self.slug(trimmed)
        UserDefaults.standard.set(userID, forKey: Keys.userID)
        UserDefaults.standard.set(displayName, forKey: Keys.displayName)
        status = .signedIn
    }

    /// Processes a Sign in with Apple result. Note: the entitlement requires a
    /// paid Apple Developer account to actually authorize; on a free account this
    /// returns a failure and the user falls back to the name login.
    func handleApple(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
            userID = "apple:" + credential.user
            if let given = credential.fullName?.givenName, !given.isEmpty {
                displayName = given
            } else if displayName.isEmpty {
                displayName = "Friend"
            }
            UserDefaults.standard.set(userID, forKey: Keys.userID)
            UserDefaults.standard.set(displayName, forKey: Keys.displayName)
            status = .signedIn
        case .failure(let error):
            print("AuthManager: Apple sign in failed — \(error.localizedDescription)")
        }
    }

    func signOut() {
        userID = ""
        displayName = ""
        UserDefaults.standard.removeObject(forKey: Keys.userID)
        UserDefaults.standard.removeObject(forKey: Keys.displayName)
        status = .signedOut
    }

    /// A stable, identifier-safe slug for an arbitrary display name.
    private static func slug(_ name: String) -> String {
        let mapped = name.lowercased().unicodeScalars.map {
            CharacterSet.alphanumerics.contains($0) ? Character($0) : "-"
        }
        return String(mapped)
    }
}
