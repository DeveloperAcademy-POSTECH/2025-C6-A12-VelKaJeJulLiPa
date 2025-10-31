//
//  FirebaseAuthManager.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import Foundation
import AuthenticationServices
import CryptoKit
import Combine
import SwiftUI

import FirebaseAuth
import FirebaseMessaging
import FirebaseFirestore


final class FirebaseAuthManager: ObservableObject {
  static let shared = FirebaseAuthManager()
  private let firebaseAuth = Auth.auth()
  
  @AppStorage(UserDefaultsKey.hasLaunchedBefore.rawValue) var hasLaunchedBefore: Bool = false
  
  @Published var user: FirebaseAuth.User?
  @Published var userInfo: User?
  @Published var authenticationState: AuthenticationState = .unauthenticated
  @Published var needsNameSetting: Bool = false
  
  private var authStateHandler: AuthStateDidChangeListenerHandle?
  private var currentNonce: String?
  
  /// 현재 선택된 유저의 팀스페이스 입니다.
  var currentTeamspace: Teamspace?
  var isSigningIn: Bool = false
  
  private init() {
    // 앱을 다시 다운로드했는데, 자동으로 로그인되지 않게 하기 위한 로그아웃
    if !hasLaunchedBefore {
      Task {
        do {
          try firebaseAuth.signOut()
        }
      }
      hasLaunchedBefore = true
    }
    
    // 현재 사용자 인증 상태 확인 + 사용자 데이터 가져오기
    if let user = firebaseAuth.currentUser {
      self.user = user
      self.authenticationState = .authenticated
    } else {
      self.authenticationState = .unauthenticated
    }
    
    registerAuthStateHandler()
    verifySignInWithAppleAuthenticationState()
    print("FirebaseAuthManager initialized")
  }
  
  /// 사용자 인증 상태를 확인하는 리스너를 등록하는 메서드
  /// - 로그인 및 로그아웃 시점에 리스너가 알려주는 인증상태를 앱에 반영합니다.
  func registerAuthStateHandler() {
    guard authStateHandler == nil else { return }
    authStateHandler = firebaseAuth.addStateDidChangeListener { auth, user in
      self.user = user
      guard !self.isSigningIn else { return }
      
      if let user = user {
        Task { try await self.fetchUserInfo(for: user.uid) }
      } else {
        print("user == nil 이어서 userInfo 도 nil 로 세팅됨")
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
  func fetchUserInfo(for uid: String) async throws {
    print("Fetch user information for \(uid)")
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
      print("Failed to fetch user information: \(FirestoreError.fetchFailed(underlying: error).localizedDescription)")
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
          print("Apple credential still valid")
          break
        case .revoked, .notFound:
          do {
            try firebaseAuth.signOut()
          }
        default:
          break
        }
      } catch {
        print("verifySignInWithAppleAuthenticationState error: \(AuthenticationError.appleAuthorizationFailed.localizedDescription)")
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
  /// - 수행 순서:
  ///   1. FCM 토큰 삭제
  ///   2. Firestore에서 fcm_token 필드 삭제
  ///   3. 앱 뱃지 초기화
  ///   4. Firebase 인증 로그아웃 (인증상태 리스너 작동으로 화면 전환됨)
  func signOut() async throws {
      print("AuthManager 로그아웃 누름")

      // ① FCM 토큰 삭제(비활성화) - DB에서 삭제되는 것은 아님
      // FIXME: 재로그인 시 토큰이 다시 갱신되어서 푸시 알림 잘 오는지 확인
//      try await Messaging.messaging().deleteToken()
//      print("🧹 FCM 토큰 삭제 완료")

      // ③ 앱 뱃지 초기화
      try await UNUserNotificationCenter.current().setBadgeCount(0)
      print("🔢 뱃지 카운트 0으로 초기화 완료")

      // ④ Firebase 로그아웃
      try firebaseAuth.signOut()
      print("✅ Firebase 로그아웃 완료, currentUser: \(String(describing: firebaseAuth.currentUser))")
  }

  
  /// Firebase Authentication 계정 삭제 메서드
  /// 1. 토큰 취소하기 위해  (Revoke Access / Refresh Token) 애플 로그인
  /// 2. 마지막 로그인이 현재 기준 5분 넘었다면 Firebase Authentication 에 재인증 필요
  /// 3. 사용자 DB 정보 삭제
  /// 4. Firebase Authentication 계정 삭제 후  자동 로그아웃
  func deleteAccount() async throws {
    guard let user = user else {
      throw AuthenticationError.userNotFound
    }
    guard let lastSignInDate = user.metadata.lastSignInDate else {
      throw AuthenticationError.lastSignInDateMissing
    }
    
    let needsReauth = !lastSignInDate.isWithinPast(minutes: 5)
    let needsTokenRevocation = user.providerData.contains { $0.providerID == "apple.com" }
    
    // Step 1 — 재인증
    var authCodeString: String?
    
    if needsReauth || needsTokenRevocation {
      let helper = SignInAppleHelper() // 애플 로그인 실행
      let tokens = try await helper.startSignInWithAppleFlow()
      let credential = OAuthProvider.appleCredential(
        withIDToken: tokens.token,
        rawNonce: tokens.nonce,
        fullName: tokens.fullName
      )
      
      if needsReauth {
        do {
          try await user.reauthenticate(with: credential) // Firebase Authentication 재인증
        } catch {
          throw AuthenticationError.reauthenticationFailed(underlying: error)
        }
      }
      
      if needsTokenRevocation {
        guard let authCodeData = tokens.appleIDCredential.authorizationCode,
              let codeString = String(data: authCodeData, encoding: .utf8)
        else {
          throw AuthenticationError.appleAuthorizationFailed
        }
        authCodeString = codeString
      }
    }
    
    // Step 2 — 병렬 작업 실행
    try await withThrowingTaskGroup(of: Void.self) { group in
      
      // 1. 애플 로그인 토큰 취소
      if let authCode = authCodeString {
        group.addTask {
          do {
            try await self.firebaseAuth.revokeToken(withAuthorizationCode: authCode)
          } catch {
            throw AuthenticationError.revokeTokenFailed(underlying: error)
          }
        }
      }
      
      // 2. Firestore 사용자 데이터 삭제
      group.addTask {
        do {
          try await FirestoreManager.shared.delete(collectionType: .users, documentID: user.uid)
        } catch {
          throw FirestoreError.deleteFailed(underlying: error)
        }
      }
      
      // 3. Firebase Authentication 계정 삭제
      group.addTask {
        do {
          try await user.delete()
        } catch {
          throw AuthenticationError.userAccountDeleteFailed(underlying: error)
        }
      }
      
      try await group.waitForAll()
    }
  }
}


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
