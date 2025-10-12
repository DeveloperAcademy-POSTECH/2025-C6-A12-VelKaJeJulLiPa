//
//  FirebaseAuthManager.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import Foundation
import FirebaseAuth
import AuthenticationServices
import CryptoKit
import Combine


struct AuthDataResultModel {
    let uid: String
    let email: String?
    
    init(user: FirebaseAuth.User) {
        self.uid = user.uid
        self.email = user.email
    }
}

enum AuthenticationState {
    case unauthenticated
    case authenticated
}


final class FirebaseAuthManager: ObservableObject {

    static let shared = FirebaseAuthManager()

    @Published var user: FirebaseAuth.User?
    @Published var authenticationState: AuthenticationState = .unauthenticated

    private var authStateHandler: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?
    
    private init() {
        // Sign out every time app is download or re-download and is launched for the first time.
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        if !hasLaunchedBefore {
            self.signOut()
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        }
        
        // Check authentication state
        if let user = Auth.auth().currentUser {
            self.user = user
            self.authenticationState = .authenticated
            print("✅ Found cached Firebase user: \(user.uid)")
        } else {
            self.authenticationState = .unauthenticated
        }

        registerAuthStateHandler()
        verifySignInWithAppleAuthenticationState()
        print("🔥 FirebaseAuthManager initialized")
    }
    
    // AuthStateHandler listens to and changes authentication state
    func registerAuthStateHandler() {
        guard authStateHandler == nil else { return }
        
        authStateHandler = Auth.auth().addStateDidChangeListener { auth, user in
            print("🎧 Listener triggered!")
            self.user = user
            self.authenticationState = user == nil ? .unauthenticated : .authenticated
            if let user = user {
                print("✅ Firebase user restored: \(user.uid)")
            } else {
                print("👋 No active user — unauthenticated.")
            }
        }
    }
    
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            print("👋 Signed out")
        } catch {
            print("❌ SignOut failed: \(error.localizedDescription)")
        }
    }
    
    
    func updateDisplayName(for user: FirebaseAuth.User, with displayName: String, force: Bool = false) async {
        if let currentDisplayName = Auth.auth().currentUser?.displayName, !currentDisplayName.isEmpty {
            // current user is non-empty, don't overwrite it
            return
        }
        else {
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            do {
                try await changeRequest.commitChanges()
                print("✅ Updated display name: \(displayName)")
            }
            catch {
                print("❌ Failed to update display name: \(error.localizedDescription)")
            }
        }
    }
    
    
    func verifySignInWithAppleAuthenticationState() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        guard let providerData = Auth.auth().currentUser?.providerData.first(where: { $0.providerID == "apple.com" }) else { return }
        
        Task {
            do {
                let credentialState = try await appleIDProvider.credentialState(forUserID: providerData.uid)
                switch credentialState {
                case .authorized:
                    print("🍎 Apple credential still valid")
                case .revoked, .notFound:
                    print("🍎 Apple credential revoked — signing out")
                    self.signOut()
                default:
                    break
                }
            } catch {
                print("⚠️ verifySignInWithAppleAuthenticationState error: \(error.localizedDescription)")
            }
        }
    }
}


// MARK: - Sign in with Apple
extension FirebaseAuthManager {
    
    @discardableResult
    func signInWithApple(tokens: SignInWithAppleResult) async throws -> AuthDataResult {
        let credential = OAuthProvider.credential(providerID: .apple, idToken: tokens.token, rawNonce: tokens.nonce)
        return try await signIn(credential: credential)
    }
    
    func signIn(credential: AuthCredential) async throws -> AuthDataResult {
        let authDataResult = try await Auth.auth().signIn(with: credential)
        return authDataResult
    }
}
