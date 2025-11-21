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


final class LoginViewModel: ObservableObject {
  @Published var isLoading = false
  @Published var isNewUser = false
  
  /// 애플 로그인을 담담하는 메서드
  /// - SigninwithAppleHelper 파일에서 소셜 로그인 플로우를 담당
  /// - 애플에서 제공해주는 사용자 정보로 Firebase Authentication 계정 생성
  /// - DB에 사용자 정보가 있으면, 사용자 정보를 세팅하고 authenticated 상태로 전환
  /// - DB에 사용자 정보가 없으면, 신규 회원이므로, 이용약관으로 화면 이동
  func signInApple() async {
    isLoading = true
    FirebaseAuthManager.shared.isSigningIn = true
    
    defer { isLoading = false }
    
    do {
      let helper = SignInAppleHelper()
      let tokens = try await helper.startSignInWithAppleFlow()
      let authDataResult = try await FirebaseAuthManager.shared.signInWithApple(tokens: tokens)
      FirebaseAuthManager.shared.user = Auth.auth().currentUser
      
      let fcmToken = UserDefaults.standard.string(forKey: UserDefaultsKey.fcmToken.rawValue) ?? "Unknown"
      
      let user = User(userId: authDataResult.user.uid,
                      email: authDataResult.user.email ?? "Unknown",
                      name: FirebaseAuthManager.shared.displayName(from: authDataResult.user.displayName),
                      loginType: LoginType.apple,
                      status: UserStatus.active,
                      fcmToken: fcmToken,
                      termsAgreed: true,
                      privacyAgreed: true)
      
      let existingUser: User? = try? await FirestoreManager.shared.get(user.userId, from: .users)
      if existingUser != nil {
        isNewUser = false
        try await FirestoreManager.shared.updateFields(
          collection: .users,
          documentId: user.userId,
          asDictionary: [User.CodingKeys.fcmToken.rawValue: fcmToken]
        )
        let userInfo: User = try await FirestoreManager.shared.get(user.userId, from: .users)
        try await FirestoreManager.shared.updateUserLastLogin(userInfo)
        FirebaseAuthManager.shared.userInfo = userInfo
        FirebaseAuthManager.shared.didCompleteAuthFlow = true
        FirebaseAuthManager.shared.isSigningIn = false
        FirebaseAuthManager.shared.authenticationState = .authenticated
      } else {
        FirebaseAuthManager.shared.userInfo = user
        isNewUser = true
      }
      print("signInApple done with authenticationState updated")
    } catch {
      print("signInApple error: \(error.localizedDescription)")
    }
  }
}
