//
//  NameSettingViewModel.swift
//  DanceMachine
//
//  Created by Paidion on 10/14/25.
//

import Combine
import FirebaseAuth

@Observable
final class NameSettingViewModel {
  private let authManager = FirebaseAuthManager.shared
  private let storeManager = FirestoreManager.shared
  
  var displayName: String = ""
  var isLoading: Bool = false
  var showError: Bool = false
  
  init() {
    displayName = authManager.displayName(from: authManager.user?.displayName)
  }
  
  /// 사용자 이름을 업데이트하는 메서드
  /// - Parameters:
  ///     - name: 수정할 사용자 이름
  func updateUserName(name: String) async throws {
    isLoading = true
    defer { isLoading = false }
    
    do {
      try await storeManager.updateFields(
        collection: .users,
        documentId: authManager.user?.uid ?? "",
        asDictionary: [User.CodingKeys.name.stringValue: name]
      )
    } catch {
      print(error.localizedDescription)
    }
  }
  
  
  /// 신규 사용자를 Firestore에 생성하는 메서드
  /// - Parameters:
  ///     - name: 사용자가 TextField에서 입력한 이름
  func createNewuser(name: String) async throws {
    print("🆕 [NameSettingViewModel] createNewuser 시작")
    print("   입력된 이름: \(name)")

    isLoading = true
    defer { isLoading = false }

    guard let userInfo = authManager.userInfo else {
      print("❌ [NameSettingViewModel] authManager.userInfo가 nil")
      throw AuthenticationError.userNotFound
    }

    print("📋 [NameSettingViewModel] 현재 userInfo:")
    print("   userId: \(userInfo.userId)")
    print("   email: \(userInfo.email.isEmpty ? "(빈 문자열)" : userInfo.email)")
    print("   name: \(userInfo.name.isEmpty ? "(빈 문자열)" : userInfo.name)")

    // TextField 값으로 새로운 User 객체 생성
    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trimmedName.isEmpty else {
      print("❌ [NameSettingViewModel] 이름이 비어있습니다")
      showError = true
      throw AuthenticationError.userNotFound
    }

    // email 처리: Firebase Auth에서 재확인 (없으면 빈 문자열 유지)
    var email = userInfo.email
    if email.isEmpty {
      print("⚠️ [NameSettingViewModel] email이 빈 문자열입니다")

      // Firebase Auth의 email 재확인
      if let authEmail = authManager.user?.email, !authEmail.isEmpty {
        email = authEmail
        print("✅ [NameSettingViewModel] Firebase Auth에서 email 찾음: \(email)")
      } else {
        print("⚠️ [NameSettingViewModel] email 없이 저장됨 (Apple이 email 제공 안함)")
      }
    }

    let newUser = User(
      userId: userInfo.userId,
      email: email,  // Firebase Auth email 또는 dummy email
      name: trimmedName,  // ← TextField 값 사용!
      loginType: LoginType(rawValue: userInfo.loginType) ?? .apple,
      status: UserStatus(rawValue: userInfo.status) ?? .active,
      fcmToken: userInfo.fcmToken,
      termsAgreed: userInfo.termsAgreed,
      privacyAgreed: userInfo.privacyAgreed
    )

    print("✅ [NameSettingViewModel] Firestore에 저장할 User 객체:")
    print("   userId: \(newUser.userId)")
    print("   email: \(newUser.email)")
    print("   name: \(newUser.name)")

    do {
      try await storeManager.createUser(newUser)
      print("✅ [NameSettingViewModel] Firestore 저장 성공")

      // authManager.userInfo도 업데이트
      authManager.userInfo = newUser
    } catch {
      print("❌ [NameSettingViewModel] Firestore 저장 실패: \(error.localizedDescription)")
      showError = true
      throw FirestoreError.addFailed(underlying: error)
    }
  }
  
  
  ///  - FirebaseAuthManager 의 authenticationState이 true가 되면 RootView 로 화면이 전환됩니다.
  func completeNameSetting() {
    authManager.completeAuthFlow()
  }
}
