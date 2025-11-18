//
//  TeamspaceSettingViewModel.swift
//  DanceMachine
//
//  Created by 김진혁 on 11/19/25.
//

import Foundation

protocol MemberManagementViewModelProtocol: AnyObject {
  /// 팀스페이스 owner를 교체하는 메서드입니다.
  /// - Parameter userId: owner가 될 userId
  /// - 사용처: MemberManagementView 의 "팀장 권한 주기" 버튼
  func updateTeamspaceOwner(userId: String) async throws
}

// MARK: - MemberManagementView 관련 메서드
// MemberManagementView 에서 사용하는 로직
extension TeamspaceSettingViewModel: MemberManagementViewModelProtocol {
  
  /// 팀스페이스 owner를 교체하는 메서드입니다.
  /// - Parameters:
  ///   - userId: owner가 될 userId
  /// - 사용처: MemberManagementView 의 "팀장 권한 주기" 버튼
  func updateTeamspaceOwner(userId: String) async throws {
    let data: [String: Any] = [
      Teamspace.CodingKeys.ownerId.stringValue: userId
    ]
    
    do {
      try await FirestoreManager.shared.updateFields(
        collection: .teamspace,
        documentId: currentTeamspace?.teamspaceId.uuidString ?? "",
        asDictionary: data
      )
    } catch {
      print("updateTeamspaceOwner error: \(error.localizedDescription)") // FIXME: - 에러 분기 처리 구현
    }
  }
}
