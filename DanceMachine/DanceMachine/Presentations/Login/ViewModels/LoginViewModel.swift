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
import FirebaseFirestore
import FirebaseFunctions


final class LoginViewModel: ObservableObject {
  @Published var isLoading = false
  @Published var isNewUser = false
  @Published var showError = false
  
  @Published var adminLoginError: String? = nil
  @Published var adminLoginSuccess: Bool = false
  
  /// 애플 로그인을 담당하는 메서드
  /// - SigninwithAppleHelper 파일에서 소셜 로그인 플로우를 담당
  /// - 애플에서 제공해주는 사용자 정보로 Firebase Authentication 계정 생성
  /// - DB에 사용자 정보가 있으면, 사용자 정보를 세팅하고 authenticated 상태로 전환
  /// - DB에 사용자 정보가 없으면, 신규 회원이므로, 이용약관으로 화면 이동
  func signInApple() async throws {
    print("🚀 [LoginViewModel] signInApple 시작")
    isLoading = true
    FirebaseAuthManager.shared.isSigningIn = true

    defer {
      isLoading = false
      print("✅ [LoginViewModel] signInApple 종료 - isNewUser: \(isNewUser)")
    }

    do {
      // 1. Apple Sign-In
      print("📱 [LoginViewModel] Apple Sign-In 시작")
      let helper = SignInAppleHelper()
      let tokens = try await helper.startSignInWithAppleFlow()

      // 2. Firebase Authentication
      print("🔐 [LoginViewModel] Firebase Authentication 시작")
      let authDataResult = try await FirebaseAuthManager.shared.signInWithApple(tokens: tokens)
      FirebaseAuthManager.shared.user = Auth.auth().currentUser

      let uid = authDataResult.user.uid
      let fcmToken = UserDefaults.standard.string(forKey: UserDefaultsKey.fcmToken.rawValue) ?? ""

      print("✅ [LoginViewModel] Firebase UID: \(uid)")
      print("   FCM Token: \(fcmToken.isEmpty ? "없음" : "있음")")

      // 2-1. transfer_sub 확인 및 Migration 시도
      if let transferSub = tokens.transferSub {
        print("🔄 [LoginViewModel] transfer_sub 감지 - Migration 시도")
        await attemptMigration(
          transferSub: transferSub,
          currentUid: uid,
          email: authDataResult.user.email,
          name: FirebaseAuthManager.shared.displayName(from: authDataResult.user.displayName),
          fcmToken: fcmToken
        )
        // Migration 후 return (함수 내에서 로그인 완료 처리)
        return
      }

      // 3. 기존 유저 확인 (명시적 에러 처리)
      print("🔍 [LoginViewModel] Firestore에서 기존 유저 조회 시작")

      do {
        let existingUser: User = try await FirestoreManager.shared.get(uid, from: .users)

        // 기존 유저 확정
        print("✅ [LoginViewModel] 기존 유저 확인")
        print("   이름: \(existingUser.name)")
        print("   이메일: \(existingUser.email)")

        isNewUser = false

        // FCM 토큰만 업데이트
        if !fcmToken.isEmpty {
          print("📱 [LoginViewModel] FCM 토큰 업데이트 중")
          try await FirestoreManager.shared.updateLastLoginFields(
            collection: .users,
            documentId: uid,
            asDictionary: [
              User.CodingKeys.fcmToken.rawValue: fcmToken,
              User.CodingKeys.updatedAt.rawValue: FieldValue.serverTimestamp()
            ]
          )
        }

        // ⚠️ 중요: 기존 조회한 existingUser 사용 (재조회 불필요)
        FirebaseAuthManager.shared.userInfo = existingUser
        FirebaseAuthManager.shared.didCompleteAuthFlow = true
        FirebaseAuthManager.shared.isSigningIn = false
        FirebaseAuthManager.shared.authenticationState = .authenticated

        print("✅ [LoginViewModel] 기존 유저 로그인 완료")

      } catch {
        // Firestore 조회 실패 → 신규 유저
        print("ℹ️ [LoginViewModel] Firestore에서 유저 없음 → 신규 유저")
        print("   에러: \(error.localizedDescription)")

        isNewUser = true

        // ⚠️ 중요: 신규 유저용 임시 User 객체 생성
        // 주의: email과 name이 빈 문자열일 수 있음 (회원가입 화면에서 처리)
        let tempUser = User(
          userId: uid,
          email: authDataResult.user.email ?? "",  // ← 빈 문자열 허용 (NameSettingViewModel에서 검증)
          name: FirebaseAuthManager.shared.displayName(from: authDataResult.user.displayName),
          loginType: LoginType.apple,
          status: UserStatus.active,
          fcmToken: fcmToken,
          termsAgreed: true,
          privacyAgreed: true
        )

        print("📝 [LoginViewModel] 신규 유저 임시 객체 생성")
        print("   email: \(tempUser.email.isEmpty ? "(빈 문자열)" : tempUser.email)")
        print("   name: \(tempUser.name.isEmpty ? "(빈 문자열)" : tempUser.name)")
        print("   ⚠️ 이 객체는 Firestore에 저장되지 않음 (회원가입 플로우에서 처리)")

        // 임시로 userInfo 설정 (회원가입 완료 시 정식 저장)
        FirebaseAuthManager.shared.userInfo = tempUser
      }

    } catch {
      print("❌ [LoginViewModel] signInApple 실패: \(error.localizedDescription)")
      FirebaseAuthManager.shared.isSigningIn = false
      showError = true
      throw error
    }
  }
  
  func signInWithEmail(email: String, password: String) async {

    await MainActor.run {
      self.isLoading = true
      self.adminLoginError = nil
      self.adminLoginSuccess = false
    }

    do {
      try await FirebaseAuthManager.shared.signInWithEmail(
        email: email,
        password: password
      )
      // 로그인 성공
      self.isLoading = false
      self.adminLoginSuccess = true

    } catch {
      self.isLoading = false
      self.adminLoginError = "로그인 실패: 계정 정보를 확인해 주세요."
    }

  }

  /// Apple Sign-In Migration 시도
  /// - Parameters:
  ///   - transferSub: Apple Transfer Identifier
  ///   - currentUid: 현재 Firebase UID
  ///   - email: 사용자 이메일 (옵션)
  ///   - name: 사용자 이름 (옵션)
  ///   - fcmToken: FCM 토큰
  private func attemptMigration(
    transferSub: String,
    currentUid: String,
    email: String?,
    name: String,
    fcmToken: String
  ) async {
    print("🔄 [LoginViewModel] Migration 시작")
    print("   transferSub: \(transferSub)")
    print("   currentUid: \(currentUid)")
    print("   email: \(email ?? "(nil)")")
    print("   name: \(name)")

    do {
      // Firebase Functions 호출
      let functions = Functions.functions(region: "asia-northeast3")
      let callable = functions.httpsCallable("migrateAppleUser")

      let data: [String: Any] = [
        "transferSub": transferSub,
        "currentUid": currentUid,
        "email": email ?? "",
        "name": name
      ]

      print("📡 [LoginViewModel] Functions 호출 중...")
      let result = try await callable.call(data)

      guard let response = result.data as? [String: Any],
            let success = response["success"] as? Bool else {
        print("❌ [LoginViewModel] Migration 응답 형식 오류")
        print("   response: \(result.data)")
        // Migration 실패 시 정상 플로우로 진행 (신규 유저로 처리)
        await handleMigrationFailure(currentUid: currentUid, email: email, name: name, fcmToken: fcmToken)
        return
      }

      if success {
        // Migration 성공!
        guard let migratedFrom = response["migratedFrom"] as? String else {
          print("❌ [LoginViewModel] migratedFrom 없음")
          await handleMigrationFailure(currentUid: currentUid, email: email, name: name, fcmToken: fcmToken)
          return
        }

        print("✅ [LoginViewModel] Migration 성공!")
        print("   기존 UID: \(migratedFrom)")
        print("   현재 UID: \(currentUid)")

        // 기존 UID로 사용자 정보 조회
        let existingUser: User = try await FirestoreManager.shared.get(migratedFrom, from: .users)

        print("✅ [LoginViewModel] 기존 유저 데이터 조회 성공")
        print("   이름: \(existingUser.name)")
        print("   이메일: \(existingUser.email)")

        // FCM 토큰 업데이트
        if !fcmToken.isEmpty {
          print("📱 [LoginViewModel] FCM 토큰 업데이트 중")
          try await FirestoreManager.shared.updateLastLoginFields(
            collection: .users,
            documentId: migratedFrom,
            asDictionary: [
              User.CodingKeys.fcmToken.rawValue: fcmToken,
              User.CodingKeys.updatedAt.rawValue: FieldValue.serverTimestamp()
            ]
          )
        }

        // 로그인 완료 처리
        FirebaseAuthManager.shared.userInfo = existingUser
        FirebaseAuthManager.shared.didCompleteAuthFlow = true
        FirebaseAuthManager.shared.isSigningIn = false
        FirebaseAuthManager.shared.authenticationState = .authenticated

        await MainActor.run {
          self.isNewUser = false
        }

        print("✅ [LoginViewModel] Migration 로그인 완료")

      } else {
        // Migration 실패 (기존 유저 없음)
        print("⚠️ [LoginViewModel] Migration 실패: 기존 유저 없음")
        print("   message: \(response["message"] as? String ?? "unknown")")
        await handleMigrationFailure(currentUid: currentUid, email: email, name: name, fcmToken: fcmToken)
      }

    } catch {
      print("❌ [LoginViewModel] Migration 호출 실패: \(error.localizedDescription)")
      await handleMigrationFailure(currentUid: currentUid, email: email, name: name, fcmToken: fcmToken)
    }
  }

  /// Migration 실패 시 정상 플로우로 진행 (신규 유저 처리)
  private func handleMigrationFailure(
    currentUid: String,
    email: String?,
    name: String,
    fcmToken: String
  ) async {
    print("ℹ️ [LoginViewModel] 정상 플로우로 진행 (신규 유저)")

    // Firestore에서 currentUid로 기존 유저 확인
    do {
      let existingUser: User = try await FirestoreManager.shared.get(currentUid, from: .users)

      // 이미 가입된 유저
      print("✅ [LoginViewModel] 기존 유저 확인 (Migration 없이)")
      FirebaseAuthManager.shared.userInfo = existingUser
      FirebaseAuthManager.shared.didCompleteAuthFlow = true
      FirebaseAuthManager.shared.isSigningIn = false
      FirebaseAuthManager.shared.authenticationState = .authenticated

      await MainActor.run {
        self.isNewUser = false
      }

    } catch {
      // 신규 유저
      print("ℹ️ [LoginViewModel] 신규 유저로 처리")

      let tempUser = User(
        userId: currentUid,
        email: email ?? "",
        name: name,
        loginType: LoginType.apple,
        status: UserStatus.active,
        fcmToken: fcmToken,
        termsAgreed: true,
        privacyAgreed: true
      )

      FirebaseAuthManager.shared.userInfo = tempUser

      await MainActor.run {
        self.isNewUser = true
      }
    }
  }
}
