//
//  AccountRecoveryViewModel.swift
//  DanceMachine
//
//  Created by 조재훈 on 1/13/26.
//

import Foundation
import FirebaseAuth
import FirebaseFunctions

@Observable
final class AccountRecoveryViewModel {

  // MARK: - Step 1: Name Input
  var userName: String = ""
  var isLoading: Bool = false
  var showError: Bool = false
  var errorMessage: String = ""
  var showLoadingToast: Bool = false
  var loadingToastMessage: String = ""

  // MARK: - Step 2: Teamspace Selection
  var teamspaceOptions: [TeamspaceOption] = []
  var selectedTeamspaceId: String? = nil

  // MARK: - Step 3: Result
  var recoverySuccess: Bool = false
  var recoveryMessage: String = ""

  // MARK: - Internal State
  private var candidateUserId: String? = nil
  private var correctTeamspaceIds: [String] = []
  private let functions = Functions.functions(region: "asia-northeast3")

  var currentStep: RecoveryStep = .nameInput

  enum RecoveryStep {
    case nameInput
    case teamspaceSelection
    case result
  }

  struct TeamspaceOption: Identifiable {
    let id: String
    let name: String
  }

  /// Step 1: 이름으로 계정 검색
  func findAccount() async {
    guard !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      errorMessage = "이름을 입력해주세요."
      showError = true
      return
    }

    guard let currentUid = FirebaseAuthManager.shared.user?.uid else {
      errorMessage = "로그인이 필요합니다."
      showError = true
      return
    }

    isLoading = true
    loadingToastMessage = String(localized: "계정 검색 중입니다. 잠시만 기다려주세요.")
    showLoadingToast = true
    defer {
      isLoading = false
      showLoadingToast = false
    }

    do {
      print("🔍 [AccountRecovery] 계정 검색 시작")
      print("   입력된 이름: \(userName)")
      print("   현재 UID: \(currentUid)")

      let callable = functions.httpsCallable("findAccountForRecovery")
      let data: [String: Any] = [
        "userName": userName.trimmingCharacters(in: .whitespacesAndNewlines),
        "currentUid": currentUid
      ]

      let result = try await callable.call(data)

      guard let response = result.data as? [String: Any] else {
        print("❌ [AccountRecovery] 응답 형식 오류")
        errorMessage = "서버 오류가 발생했습니다."
        showError = true
        return
      }

      guard let found = response["found"] as? Bool, found else {
        print("⚠️ [AccountRecovery] 계정을 찾을 수 없음")
        errorMessage = response["message"] as? String ?? "해당 이름의 계정을 찾을 수 없습니다."
        showError = true
        return
      }

      // 후보 계정 정보 저장
      guard let candidateId = response["candidateUserId"] as? String,
            let teamspaces = response["teamspaceOptions"] as? [[String: String]],
            let correctIds = response["correctTeamspaceIds"] as? [String] else {
        print("❌ [AccountRecovery] 응답 데이터 파싱 실패")
        errorMessage = "서버 응답 오류가 발생했습니다."
        showError = true
        return
      }

      self.candidateUserId = candidateId
      self.correctTeamspaceIds = correctIds
      self.teamspaceOptions = teamspaces.compactMap { dict in
        guard let id = dict["id"], let name = dict["name"] else { return nil }
        return TeamspaceOption(id: id, name: name)
      }

      print("✅ [AccountRecovery] 계정 검색 성공")
      print("   후보 UID: \(candidateId)")
      print("   팀스페이스 옵션 수: \(teamspaceOptions.count)")

      // Step 2로 이동
      currentStep = .teamspaceSelection

    } catch {
      print("❌ [AccountRecovery] 검색 실패: \(error.localizedDescription)")
      errorMessage = "계정 검색 중 오류가 발생했습니다."
      showError = true
    }
  }

  /// Step 2: 팀스페이스 선택 후 계정 복구
  func verifyAndRecover() async {
    guard let selectedId = selectedTeamspaceId else {
      errorMessage = "팀스페이스를 선택해주세요."
      showError = true
      return
    }

    guard let candidateId = candidateUserId else {
      errorMessage = "내부 오류가 발생했습니다."
      showError = true
      return
    }

    guard let currentUid = FirebaseAuthManager.shared.user?.uid else {
      errorMessage = "로그인이 필요합니다."
      showError = true
      return
    }

    isLoading = true
    loadingToastMessage = String(localized: "복구 중입니다. 잠시만 기다려주세요.")
    showLoadingToast = true
    defer {
      isLoading = false
      showLoadingToast = false
    }

    do {
      print("🔐 [AccountRecovery] 계정 복구 시작")
      print("   선택된 팀스페이스 ID: \(selectedId)")

      let callable = functions.httpsCallable("verifyAndRecoverAccount")
      let data: [String: Any] = [
        "candidateUserId": candidateId,
        "selectedTeamspaceId": selectedId,
        "currentUid": currentUid,
        "correctTeamspaceIds": correctTeamspaceIds
      ]

      let result = try await callable.call(data)

      guard let response = result.data as? [String: Any],
            let success = response["success"] as? Bool,
            let message = response["message"] as? String else {
        print("❌ [AccountRecovery] 응답 형식 오류")
        errorMessage = "서버 오류가 발생했습니다."
        showError = true
        return
      }

      if success {
        print("✅ [AccountRecovery] 계정 복구 성공!")
        recoverySuccess = true
        recoveryMessage = message
        currentStep = .result

        // 사용자 정보 갱신
        let refreshedUser: User = try await FirestoreManager.shared.get(currentUid, from: .users)
        FirebaseAuthManager.shared.userInfo = refreshedUser

        print("✅ [AccountRecovery] 사용자 정보 갱신 완료")

      } else {
        print("❌ [AccountRecovery] 계정 복구 실패")
        errorMessage = message
        showError = true
      }

    } catch {
      print("❌ [AccountRecovery] 복구 실패: \(error.localizedDescription)")
      errorMessage = "계정 복구 중 오류가 발생했습니다."
      showError = true
    }
  }

  /// 처음부터 다시 시작
  func reset() {
    userName = ""
    selectedTeamspaceId = nil
    teamspaceOptions = []
    candidateUserId = nil
    correctTeamspaceIds = []
    recoverySuccess = false
    recoveryMessage = ""
    errorMessage = ""
    showError = false
    currentStep = .nameInput
  }
}
