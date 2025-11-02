//
//  AccountSettingViewModel.swift
//  DanceMachine
//
//  Created by Paidion on 10/25/25.
//

import Foundation

@Observable
final class AccountSettingViewModel {
    
    var myId: String { FirebaseAuthManager.shared.userInfo?.email ?? "Unknown" }
    var errorMessage: String?
    
    //MARK: - 계정 설정
    /// 로그아웃 메서드
    func signOut() async throws {
      try await FirebaseAuthManager.shared.signOut()
    }

    
    /// 회원탈퇴 메서드
    func deleteUserAccount() async throws {
        do {
            try await FirebaseAuthManager.shared.deleteAccount()
        } catch {
            print("Delete User Failed: \(error.localizedDescription)") // FIXME: - 적절한 에러처리
        }
    }
}
