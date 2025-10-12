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
    
    init() {
        // Sign out every time app is download or re-download and is launched for the first time.
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        if !hasLaunchedBefore {
            self.signOut()
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        }
        
        // Check Authentication State
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
    
    // Handler listens to and reflects authentication state
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
    
    
    // MARK: - Sign In With Apple
    func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
        let nonce = randomNonceString()
        currentNonce = nonce
        request.nonce = sha256(nonce)
    }
    
    
    func handleSignInWithAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        if case .failure(let failure) = result {
            print("❌ Apple Sign In failed: \(failure.localizedDescription)")
            return
        }
        
        guard case .success(let authorization) = result,
              let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential
        else { return }

        
        guard let nonce = currentNonce,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8)
        else {
            print("❌ AppleID token invalid")
            return
        }
        
        let credential = OAuthProvider.credential(providerID: .apple, idToken: idTokenString, rawNonce: nonce)
        
        Task {
            do {
                let result = try await Auth.auth().signIn(with: credential)
                await updateDisplayName(for: result.user, with: appleIDCredential)
            } catch {
                print("❌ Error authenticating: \(error.localizedDescription)")
                authenticationState = .unauthenticated

            }
        }
    }
    
    
    func updateDisplayName(for user: FirebaseAuth.User, with appleIDCredential: ASAuthorizationAppleIDCredential, force: Bool = false) async {
        if let currentDisplayName = Auth.auth().currentUser?.displayName, !currentDisplayName.isEmpty {
            // current user is non-empty, don't overwrite it
            return
        }
        else {
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = appleIDCredential.displayName()
            do {
                try await changeRequest.commitChanges()
                print("✅ Updated display name: \(appleIDCredential.displayName())")
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

// MARK: - Helper Extensions
extension ASAuthorizationAppleIDCredential {
    func displayName() -> String {
        [fullName?.givenName, fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
    }
}


private func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    var randomBytes = [UInt8](repeating: 0, count: length)
    let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
    if errorCode != errSecSuccess {
        fatalError("Unable to generate nonce.")
    }
    
    let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    return String(randomBytes.map { charset[Int($0) % charset.count] })
}


private func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    return hashedData.map { String(format: "%02x", $0) }.joined()
}

