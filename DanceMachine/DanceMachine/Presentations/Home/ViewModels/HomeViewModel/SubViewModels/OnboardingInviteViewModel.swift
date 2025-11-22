//
//  OnboardingInviteViewModel.swift
//  DanceMachine
//
//  Created by 김진혁 on 11/20/25.
//

import Foundation

@Observable
final class OnboardingInviteViewModel {
  
  // 현재 선택된 팀 스페이스 (전역 FirebaseAuthManager와 연동)
  var currentTeamspace: Teamspace? { FirebaseAuthManager.shared.currentTeamspace }
  
  func makeInviteShareItem() async -> InviteShareItem? {
    // 1) 팀스페이스 id / 이름 체크
    guard let teamspaceId = currentTeamspace?.teamspaceId.uuidString else {
      print("초대링크 생성 실패: teamspaceId 없음")
      return nil
    }
    
    guard let teamspaceName = currentTeamspace?.teamspaceName else {
      print("팀 스페이스 이름 불러오기 실패")
      return nil
    }
    
    do {
      // 2) 초대 링크 생성
      let url = try await InviteService().createInvite(teamspaceId: teamspaceId)
      
      // 3) 공유 아이템 생성 후 반환
      return InviteShareItem(teamName: teamspaceName, url: url)
    } catch {
      print("초대링크 생성 실패: \(error)")
      return nil
    }
  }
}
