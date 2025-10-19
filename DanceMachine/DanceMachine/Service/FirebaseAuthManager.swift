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
import SwiftUI


final class FirebaseAuthManager: ObservableObject {
    static let shared = FirebaseAuthManager()
    private let firebaseAuth = Auth.auth()
    
    @AppStorage(UserDefaultsKey.hasLaunchedBefore.rawValue) var hasLaunchedBefore: Bool = false
    
    @Published var user: FirebaseAuth.User?
    @Published var userInfo: User?
    @Published var authenticationState: AuthenticationState = .unauthenticated
    @Published var needsNameSetting: Bool = false
    @Published var errormessage: String = ""
    
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?
    
    var isSigningIn: Bool = false
    
    private init() {
        // 앱을 다시 다운로드했는데, 자동으로 로그인되지 않게 하기 위한 로그아웃
        if !hasLaunchedBefore {
            do { try self.signOut() }
            catch {
                errormessage = error.localizedDescription
                print("❌ Failed to sign out: \(error.localizedDescription)")
            }
            hasLaunchedBefore = true
        }
        
        // 현재 사용자 인증 상태 확인 + 사용자 데이터 가져오기
        if let user = firebaseAuth.currentUser {
            self.user = user
            self.authenticationState = .authenticated
            Task { await self.fetchUserInfo(for: user.uid) }
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
            self.user = user
            guard !self.isSigningIn else { return }
            
            if let user = user {
                Task { await self.fetchUserInfo(for: user.uid) }
            } else {
                self.userInfo = nil
                self.needsNameSetting = false
                self.authenticationState = .unauthenticated
            }
        }
    }
    
    
    ///  사용자 정보 불러오기 (자동 로그인용)
    ///  - Parameters:
    ///     - uid: 사용자 id (Firebase Authentication 에서 반환 - users 콜렉션에서 id로 사용중)
    @MainActor
    func fetchUserInfo(for uid: String) async {
        print("🔄 Fetch user information for \(uid)")
        do {
            if let user: User = try await FirestoreManager.shared.get(uid, from: .users) {
                self.userInfo = user
                self.needsNameSetting = false
            } else {
                self.userInfo = nil
                self.needsNameSetting = true
            }
        } catch {
            self.authenticationState = .unauthenticated
            errormessage = error.localizedDescription
            print("❌ Failed to fetch user information: \(error.localizedDescription)")
        }
    }
    
    
    /// 애플 로그인 연동 상태를 확인하는 메서드
    /// - Sign in with Apple 과 현재 서비스 연동 상태가 유효한지 확인하고 유효하지 않다면 로그아웃합니다.
    /// - 예를 들어, Sign in with apple 을 더이상 사용하지 않겠다고 설정한 경우 로그아웃됩니다.
    func verifySignInWithAppleAuthenticationState() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        guard let providerData = firebaseAuth.currentUser?.providerData.first(where: { $0.providerID == "apple.com" }) else { return }
        
        Task {
            do {
                let credentialState = try await appleIDProvider.credentialState(forUserID: providerData.uid)
                switch credentialState {
                case .authorized:
                    print("🍎 Apple credential still valid")
                    break
                case .revoked, .notFound:
                    do {
                        try self.signOut()
                    } catch {
                        errormessage = error.localizedDescription
                        print("🍎 Apple credential revoked — signing out")
                    }
                default:
                    break
                }
            } catch {
                print("⚠️ verifySignInWithAppleAuthenticationState error: \(error.localizedDescription)")
            }
        }
    }
    
    
    /// 사용자 이름을 locale에 알맞게 보여주는 함수입니다.
    /// - Parameters:
    ///     - fullName:  사용자 이름
    ///     - locale: 사용자 로케일
    /// - Returns:
    ///     - 공백 없는 한중일 이름(CJK) 등 사용자 설정 이름겂에 구조화된 이름으로 판단할 수 없다면,  "Unknown"을 반환합니다.
    func displayName(from fullName: String?, locale: Locale = .current) -> String {
        guard let fullName = fullName,
              let nameComponents = PersonNameComponentsFormatter().personNameComponents(from: fullName) else {
            return "Unknown"
        }
        
        let formatter = PersonNameComponentsFormatter()
        formatter.style = .medium
        formatter.locale = locale
        
        return formatter.string(from: nameComponents)
    }
    
    /// 로그아웃 메서드
    /// - 로그아웃 시, 인증상태 리스너가 작동합니다.
    func signOut() throws {
        try firebaseAuth.signOut()
    }
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
