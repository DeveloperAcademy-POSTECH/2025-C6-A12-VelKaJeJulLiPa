//
//  TeamspaceNameUpdateViewModel.swift
//  DanceMachine
//
//  Created by 김진혁 on 11/19/25.
//

import Foundation

protocol TeamspaceNameUpdateViewModelProtocol: AnyObject {
  /// 팀 스페이스 이름을 업데이트 하는 메서드 입니다.
  /// - Parameters:
  ///   - teamspaceId: 팀 스페이스 Id
  ///   - newTeamspaceName: 변경 이름
  func updateTeamspaceName(teamspaceId: String, newTeamspaceName: String) async throws
  
  /// 팀 스페이스 이름 수정 + 현재 팀 스페이스/뷰모델 상태 동기화
  /// - Parameter editedName: 최종 수정된 팀 스페이스 이름
  func renameCurrentTeamspaceAndReload(editedName: String) async throws
}

// MARK: - TeamspaceNameUpdateView 관련 메서드
// TeamspaceNameUpdateView 에서 사용하는 로직

extension TeamspaceSettingViewModel: TeamspaceNameUpdateViewModelProtocol {
  
  /// 팀 스페이스 이름을 업데이트 하는 메서드 입니다.
  /// - Parameters:
  ///   - teamspaceId: 팀 스페이스 Id
  ///   - newTeamspaceName: 변경 이름
  /// - 사용처: renameCurrentTeamspaceAndReload 내부
  func updateTeamspaceName(teamspaceId: String, newTeamspaceName: String) async throws {
    try await FirestoreManager.shared.updateFields(
      collection: .teamspace,
      documentId: teamspaceId,
      asDictionary: [ Teamspace.CodingKeys.teamspaceName.stringValue: newTeamspaceName ]
    )
  }
  
  /// 팀 스페이스 이름 수정 + 현재 팀 스페이스/뷰모델 상태 동기화
  /// - 사용처: TeamspaceNameUpdateView 의 "확인" 버튼
  func renameCurrentTeamspaceAndReload(editedName: String) async throws {
    guard let id = self.currentTeamspace?.teamspaceId.uuidString else { return }
    
    // 1) Firestore에 이름 업데이트
    try await self.updateTeamspaceName(
      teamspaceId: id,
      newTeamspaceName: editedName
    )
    
    // 2) 최신 Teamspace 문서를 다시 가져옴
    let updated: Teamspace = try await FirestoreManager.shared.get(
      id,
      from: .teamspace
    )
    
    // 3) 전역 상태 + 뷰모델 상태 갱신
    await MainActor.run {
      FirebaseAuthManager.shared.currentTeamspace = updated
      self.dataState.selectedTeamspaceName = updated.teamspaceName
    }
    
    // 4) 내 유저 도큐먼트 updated_at 갱신
    try await FirestoreManager.shared.updateTimestampField(
      field: .update,
      in: .users,
      documentId: FirebaseAuthManager.shared.userInfo?.userId ?? ""
    )
  }
}

