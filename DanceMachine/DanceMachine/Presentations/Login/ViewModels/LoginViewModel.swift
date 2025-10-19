//
//  LoginViewModel.swift
//  DanceMachine
//
//  Created by Paidion on 10/9/25.
//

import Foundation
import Combine
import AuthenticationServices
import FirebaseAuth

@Observable
final class LoginViewModel {
    
    /// 애플 로그인을 담담하는 메서드
    /// - SigninwithAppleHelper 파일에서 소셜 로그인 플로우를 담당
    /// - 애플에서 제공해주는 사용자 정보로 Firebase Authentication 연동
    /// - 사용자 정보 DB에 저장 (재로그인시, 최근 로그인 시점을 함께 저장)
    func signInApple() async {
        FirebaseAuthManager.shared.isSigningIn = true
        
        defer {
            FirebaseAuthManager.shared.isSigningIn = false
        }
        
        do {
            let helper = SignInAppleHelper()
            let tokens = try await helper.startSignInWithAppleFlow()
            let authDataResult = try await FirebaseAuthManager.shared.signInWithApple(tokens: tokens)
            
            let user = User(userId: authDataResult.user.uid,
                            email: authDataResult.user.email ?? "Unknown",
                            name: FirebaseAuthManager.shared.displayName(from: authDataResult.user.displayName),
                            loginType: LoginType.apple,
                            status: UserStatus.active,
                            fcmToken: "FAKE_FCM_TOKEN",
                            termsAgreed: true,
                            privacyAgreed: true)
            
            if let existingUser: User = try? await FirestoreManager.shared.get(user.userId, from: .users) {
                try await FirestoreManager.shared.updateUserLastLogin(existingUser)
                FirebaseAuthManager.shared.userInfo = existingUser
                FirebaseAuthManager.shared.needsNameSetting = false
            } else {
                try await FirestoreManager.shared.createUser(user)
                FirebaseAuthManager.shared.userInfo = user
                FirebaseAuthManager.shared.needsNameSetting = true
            }
            
            FirebaseAuthManager.shared.authenticationState = .authenticated
            print("✅ signInApple done with authenticationState updated")
        } catch {
            print("⚠️ signInApple error: \(error.localizedDescription)")
        }
    }
}
