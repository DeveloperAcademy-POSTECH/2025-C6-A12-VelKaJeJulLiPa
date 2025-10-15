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


final class FirebaseAuthManager: ObservableObject {

    static let shared = FirebaseAuthManager()
    private let firebaseAuth = Auth.auth()

    @Published var user: FirebaseAuth.User?
    @Published var authenticationState: AuthenticationState = .unauthenticated
    @Published var hasNameSet: Bool = UserDefaults.standard.bool(forKey:  UserDefaultsKey.hasNameSet.rawValue)

    private var authStateHandler: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?
    
    private init() {
        // 앱을 다시 다운로드했는데, 자동으로 로그인되지 않게 하기 위한 로그아웃
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey:  UserDefaultsKey.hasLaunchedBefore.rawValue)
        if !hasLaunchedBefore {
            do {
                try self.signOut()
                UserDefaults.standard.set(true, forKey: UserDefaultsKey.hasLaunchedBefore.rawValue)
            } catch {
                print("❌ SignOut failed: \(error.localizedDescription)")            }
        }
        
        // 현재 사용자 인증 상태 확인
        if let user = firebaseAuth.currentUser {
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
    
    /// 사용자 인증 상태를 확인하는 리스너를 등록하는 메서드
    /// - 로그인 및 로그아웃 시점에 리스너가 알려주는 인증상태를 앱에 반영합니다.
    func registerAuthStateHandler() {
        guard authStateHandler == nil else { return }
        
        authStateHandler = firebaseAuth.addStateDidChangeListener { auth, user in
            print("🎧 Authentication Listener triggered!")
            self.user = user
            self.authenticationState = user == nil ? .unauthenticated : .authenticated
            //FIXME: 주석 삭제
            if let user = user {
                print("✅ Firebase user restored: \(user.uid)")
                print("✅ Firebase user email: \(user.email ?? "")")
                print("✅ Firebase user displayName: \(user.displayName ?? "")")
            } else {
                print("👋 No active user — unauthenticated.")
            }
        }
    }
    
    /// 애플 로그인 연동 상태를 확인하는 메서드
    /// - Sign in with Apple 과 현재 서비스 연동 상태가 유효한지 확인하고 유효하지 않다면 로그아웃합니다.
    /// - 예를 들어, Sign in with apple 을 더이상 사용하지 않겠다고 설정한 경우 로그아웃됩니다.
    func verifySignInWithAppleAuthenticationState() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        guard let providerData = Auth.auth().currentUser?.providerData.first(where: { $0.providerID == "apple.com" }) else { return }
        
        Task {
            do {
                let credentialState = try await appleIDProvider.credentialState(forUserID: providerData.uid)
                switch credentialState {
                case .authorized:
                    print("🍎 Apple credential still valid")
                    break
                case .revoked, .notFound:
                    try self.signOut()
                    print("🍎 Apple credential revoked — signing out")
                default:
                    break
                }
            } catch {
                print("⚠️ verifySignInWithAppleAuthenticationState error: \(error.localizedDescription)")
            }
        }
    }
    
    /// 로그아웃 메서드
    /// - 로그아웃 시, 인증상태 리스너가 작동합니다.
    func signOut() throws {
        try firebaseAuth.signOut()
    }
    
    
    /// Firebase Authentication 의 사용자 계정 삭제 메서드
    //    func deleteAuthUser() async -> Bool {
    //        try await firebaseAuth.currentUser?.delete()
    //
    //
    //
    //        return false
    //    }
    //
    
//    func deleteAccount() async throws -> Bool {
//        guard let user = user else { return false }
//        guard let lastSignInDate = user.metadata.lastSignInDate else { return false }
//        let needsReauth = !lastSignInDate.isWithinPast(minutes: 5)
//        
//        let needsTokenRevocation = user.providerData.contains { $0.providerID == "apple.com" }
//        
//        do {
//            if needsReauth || needsTokenRevocation {
//                let helper = SignInAppleHelper()
//                let tokens = try await helper.startSignInWithAppleFlow()
//                let appleIDCredential = tokens.appleIDCredential
//
//                guard
//                    let appleIDToken = appleIDCredential.identityToken,
//                    let idTokenString = String(data: appleIDToken, encoding: .utf8),
//                    let nonce = currentNonce
//                else { return false }
//                
////
//                let credential = OAuthProvider.appleCredential(withIDToken: tokens.token, rawNonce: tokens.nonce, fullName: tokens.fullName)
//                
//                if needsReauth {
//                    try await user.reauthenticate(with: credential)
//                }
//                if needsTokenRevocation {
//                    guard let authorizationCode = appleIDCredential.authorizationCode else { return false }
//                    guard let authCodeString = String(data: authorizationCode, encoding: .utf8) else { return false }
//                    
//                    try await Auth.auth().revokeToken(withAuthorizationCode: authCodeString)
//                }
//            }
//            
//            try await user.delete()
//            return true
//        }
//        catch {
//            print(error.localizedDescription)
//            return false
//        }
//    }
    
//    func deleteAccountWithRevocationHelper() async -> Bool {
//        do {
//            // add code to find out if the user is connected to SiwA
//            try await TokenRevocationHelper().revokeToken()
//            try await user?.delete()
//            return true
//        }
//        catch {
//            errorMessage = error.localizedDescription
//            return false
//        }
//    }
}


// MARK: - Sign in with Apple
extension FirebaseAuthManager {
    
    @discardableResult
    func signInWithApple(tokens: SignInWithAppleResult) async throws -> AuthDataResult {
        let credential = OAuthProvider.appleCredential(withIDToken: tokens.token, rawNonce: tokens.nonce, fullName: tokens.fullName)
        return try await signIn(credential: credential)
    }
    
    func signIn(credential: AuthCredential) async throws -> AuthDataResult {
        let authDataResult = try await firebaseAuth.signIn(with: credential)
        return authDataResult
    }
}
