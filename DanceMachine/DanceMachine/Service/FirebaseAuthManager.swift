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
  @AppStorage(UserDefaultsKey.didCompleteAuthFlow.rawValue) var didCompleteAuthFlow = false
  
  @Published var user: FirebaseAuth.User?
  @Published var userInfo: User?
  @Published var authenticationState: AuthenticationState = .unauthenticated
  
  private var authStateHandler: AuthStateDidChangeListenerHandle?
//  private var currentNonce: String?
  
  /// 현재 선택된 유저의 팀스페이스 입니다.
  @Published var currentTeamspace: Teamspace?
  var isSigningIn: Bool = false
  
  private init() {
    print("🔧 [FirebaseAuthManager] 초기화 시작")
    print("   hasLaunchedBefore: \(hasLaunchedBefore)")
    print("   didCompleteAuthFlow: \(didCompleteAuthFlow)")
    print("   currentUser: \(firebaseAuth.currentUser?.uid ?? "nil")")

    // ⚠️ 중요: hasLaunchedBefore 로직 개선
    // 앱 재설치 시에만 로그아웃하되, 더 안전하게 처리
    if !hasLaunchedBefore {
      print("⚠️ [FirebaseAuthManager] 첫 실행 감지 - 초기화 진행")

      // 현재 로그인되어 있고, 플로우 완료 안됐으면 비정상 상태
      if firebaseAuth.currentUser != nil && !didCompleteAuthFlow {
        print("🔄 [FirebaseAuthManager] 비정상 인증 상태 감지 - 로그아웃 실행")
        do {
          try firebaseAuth.signOut()
          print("✅ [FirebaseAuthManager] 강제 로그아웃 완료")
        } catch {
          print("❌ [FirebaseAuthManager] 로그아웃 실패: \(error.localizedDescription)")
        }
      } else {
        print("ℹ️ [FirebaseAuthManager] 정상 상태 - 로그아웃 불필요")
      }

      hasLaunchedBefore = true
      print("✅ [FirebaseAuthManager] hasLaunchedBefore = true 설정 완료")
    }

    // 현재 사용자 인증 상태 확인
    if let user = firebaseAuth.currentUser {
      print("👤 [FirebaseAuthManager] currentUser 존재: \(user.uid)")

      if !didCompleteAuthFlow {
        // 로그인 플로우가 완료하지 않았는데 currentUser가 있는 상태
        print("⚠️ [FirebaseAuthManager] didCompleteAuthFlow=false 이지만 currentUser 존재")
        print("   → 비정상 로그인 상태, 로그아웃 실행")
        do {
          try firebaseAuth.signOut()
          print("✅ [FirebaseAuthManager] 비정상 상태 로그아웃 완료")
        } catch {
          print("❌ [FirebaseAuthManager] 로그아웃 실패: \(error.localizedDescription)")
        }
        self.authenticationState = .unauthenticated
      } else {
        // 정상 로그인 완료된 상태
        print("✅ [FirebaseAuthManager] 정상 로그인 상태")
        self.user = user
        self.authenticationState = .authenticated
      }
    } else {
      print("🚫 [FirebaseAuthManager] currentUser 없음 - 로그아웃 상태")
      self.authenticationState = .unauthenticated
    }

    registerAuthStateHandler()
    verifySignInWithAppleAuthenticationState()
    print("✅ [FirebaseAuthManager] 초기화 완료")
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
        self.authenticationState = .unauthenticated
      }
    }
  }
  
  
  func completeAuthFlow() {
    self.isSigningIn = false
    self.didCompleteAuthFlow = true
    self.authenticationState = .authenticated
  }
  
  
  ///  사용자 정보 불러오기 (자동 로그인용)
  ///  - Parameters:
  ///     - uid: 사용자 id (Firebase Authentication 에서 반환 - users 콜렉션에서 id로 사용중)
  @MainActor
  func fetchUserInfo(for uid: String) async throws {
    print("🔍 [FirebaseAuthManager] fetchUserInfo 시작 - uid: \(uid)")
    do {
      if let user: User = try await FirestoreManager.shared.get(uid, from: .users) {
        print("✅ [FirebaseAuthManager] Firestore에서 유저 조회 성공")
        print("   name: \(user.name)")
        print("   email: \(user.email)")
        self.userInfo = user
      } else {
        print("⚠️ [FirebaseAuthManager] Firestore에서 유저 없음 (nil)")
        self.userInfo = nil
      }
    } catch {
      print("❌ [FirebaseAuthManager] fetchUserInfo 실패: \(error.localizedDescription)")
      self.authenticationState = .unauthenticated
      throw error
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
      return ""
    }
    
    let formatter = PersonNameComponentsFormatter()
    formatter.style = .medium
    formatter.locale = locale
    
    return formatter.string(from: nameComponents)
  }
  
  
  /// 로그아웃 메서드
  /// - 수행 순서:
  ///   1. Firestore에서 fcm_token 빈 문자열("")로 저장
  ///   3. 앱 뱃지 초기화
  ///   4. Firebase 인증 로그아웃 (인증상태 리스너 작동으로 화면 전환됨)
  func signOut() async throws {
    //FCM 토큰 빈 문자열 처리 (로그아웃한 사용자는 알림 받지 않을 수 있도록)
    try await FirestoreManager.shared.updateFields(
      collection: .users,
      documentId: self.userInfo?.userId ?? "",
      asDictionary: [ User.CodingKeys.fcmToken.rawValue: "" ]
    )
    
    //앱 뱃지 초기화
    try await UNUserNotificationCenter.current().setBadgeCount(0)
    print("🔢 뱃지 카운트 0으로 초기화 완료")
    
    //Firebase 로그아웃
    try firebaseAuth.signOut()
    
    //로그인 플로우 초기화
    didCompleteAuthFlow = false
    
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
    
    // Step 2 — 유저가 속한 모든 팀스페이스에서 members 제거
    do {
      // 유저의 user_teamspace 서브컬렉션에서 팀스페이스 목록 가져오기
      let userTeamspaces: [UserTeamspace] = try await FirestoreManager.shared.fetchAllFromSubcollection(
        under: .users,
        parentId: user.uid,
        subCollection: .userTeamspace
      )

      // 각 팀스페이스의 members 서브컬렉션에서 유저 제거
      for userTeamspace in userTeamspaces {
        let teamspaceId = userTeamspace.teamspaceId
        do {
          try await FirestoreManager.shared.deleteFromSubcollection(
            under: .teamspace,
            parentId: teamspaceId,
            subCollection: .members,
            target: user.uid
          )
          print("✅ 팀스페이스 \(teamspaceId)에서 멤버 제거 완료")
        } catch {
          print("⚠️ 팀스페이스 \(teamspaceId)에서 멤버 제거 실패: \(error.localizedDescription)")
          // 계속 진행 (일부 실패해도 나머지는 삭제)
        }
      }
    } catch {
      print("⚠️ 팀스페이스 멤버 제거 중 오류 발생: \(error.localizedDescription)")
      // 계속 진행 (팀스페이스 정리 실패해도 계정 삭제는 진행)
    }

    // Step 3 — 병렬 작업 실행
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

      //로그인 플로우 초기화
      didCompleteAuthFlow = false
    }
  }
}


extension FirebaseAuthManager {
  
  @discardableResult
  func signInWithApple(tokens: SignInWithAppleResult) async throws -> AuthDataResult {
    print("🔐 [FirebaseAuthManager] signInWithApple 시작")
    print("   Apple User ID: \(tokens.appleUserId)")

    let credential = OAuthProvider.appleCredential(
      withIDToken: tokens.token,
      rawNonce: tokens.nonce,
      fullName: tokens.fullName
    )

    let authDataResult = try await signIn(credential: credential)

    print("🔑 [FirebaseAuthManager] Firebase UID: \(authDataResult.user.uid)")
    print("   Provider ID: \(authDataResult.user.providerID)")

    // ⚠️ 중요: UID 변경 감지
    if let existingUID = UserDefaults.standard.string(forKey: "lastKnownUID_\(tokens.appleUserId)") {
      if existingUID != authDataResult.user.uid {
        print("🚨🚨🚨 [FirebaseAuthManager] UID 변경 감지!")
        print("   기존 UID: \(existingUID)")
        print("   새 UID: \(authDataResult.user.uid)")
        print("   Apple User ID: \(tokens.appleUserId)")
      } else {
        print("✅ [FirebaseAuthManager] UID 일치")
      }
    } else {
      print("📝 [FirebaseAuthManager] 첫 로그인 - UID 저장")
    }

    // UID 저장 (다음번 로그인 시 비교용)
    UserDefaults.standard.set(authDataResult.user.uid, forKey: "lastKnownUID_\(tokens.appleUserId)")

    return authDataResult
  }

  func signIn(credential: AuthCredential) async throws -> AuthDataResult {
    let authDataResult = try await firebaseAuth.signIn(with: credential)

    // additionalUserInfo 확인 (디버깅용)
    if let additionalUserInfo = authDataResult.additionalUserInfo {
      print("ℹ️ [FirebaseAuthManager] isNewUser: \(additionalUserInfo.isNewUser)")
      print("   profile: \(additionalUserInfo.profile ?? [:])")
    }

    return authDataResult
  }
  
  // 애플 심사 어드민 email 로그인
  func signInWithEmail(email: String, password: String) async throws {
    do {
      // Firebae Authentication 로그인
      let authResult = try await firebaseAuth.signIn(
        withEmail: email,
        password: password
      )
      
      let uid = authResult.user.uid
      
      // FIrestore 사용자 정보 패치
      guard let userDoc: User = try await FirestoreManager.shared.get(
        uid,
        from: .users
      ) else {
        try firebaseAuth.signOut()
        throw AuthenticationError.userNotFound
      }
      self.userInfo = userDoc
      self.completeAuthFlow()
    } catch {
      throw error
    }
  }
}
