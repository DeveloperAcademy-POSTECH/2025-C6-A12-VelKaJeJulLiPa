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
  func updateTeamspaceOwner(userId: String) async throws
}

// MARK: - MemberManagementView 관련 메서드
// MemberManagementView 에서 사용하는 로직
extension TeamspaceSettingViewModel: MemberManagementViewModelProtocol {
  
  func updateTeamspaceOwner(userId: String) async throws {
    // 0) 현재 팀스페이스 id 확보
    guard let teamspaceId = currentTeamspace?.teamspaceId.uuidString else {
      print("updateTeamspaceOwner error: currentTeamspace nil")
      return
    }
    
    let data: [String: Any] = [
      Teamspace.CodingKeys.ownerId.stringValue: userId
    ]
    
    // 1) Firestore 에 ownerId 필드 업데이트
    try await FirestoreManager.shared.updateFields(
      collection: .teamspace,
      documentId: teamspaceId,
      asDictionary: data
    )
    
    // 2) 최신 Teamspace 문서를 다시 가져오기
    let updated: Teamspace = try await FirestoreManager.shared.get(
      teamspaceId,
      from: .teamspace
    )
    
    // 3) 전역 상태 + 뷰모델 상태 반영
    await MainActor.run {
      // 전역 currentTeamspace 갱신
      FirebaseAuthManager.shared.currentTeamspace = updated
      
      // 내 역할(owner / viewer) 다시 계산
      self.dataState.teamspaceRole = self.isTeamspaceOwner() ? .owner : .viewer
    }
  }
}
