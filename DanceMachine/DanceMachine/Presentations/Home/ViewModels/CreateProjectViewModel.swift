//
//  CreateProjectViewModel.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/17/25.
//

import Foundation

@Observable
final class CreateProjectViewModel {
  
  var currentTeamspace: Teamspace? { FirebaseAuthManager.shared.currentTeamspace }
  
  /// 해당 팀스페이스의 프로젝트를 생성하는 메서드입니다.
  /// - Parameters:
  ///     - projectName: 프로젝트 이름 설정
  func createProject(projectName: String) async throws {
    do {
      // FIXME: - batch 추가하기
      /// 프로젝트 생성
      let project: Project = .init(
        projectId: UUID(),
        teamspaceId: self.currentTeamspace?.teamspaceId.uuidString ?? "",
        creatorId: FirebaseAuthManager.shared.userInfo?.userId ?? "",
        projectName: projectName
      )
      try await FirestoreManager.shared.create(project)
      
      /// 팀 스페이스 updated_at 갱신
      // TODO: 프로젝트 생성은 updated_at 갱신 완료했고, 프로젝트 수정,삭제 될 때도 갱신되게 하기
      try await FirestoreManager.shared.updateTimestampField(
        field: .update,
        in: .teamspace,
        documentId: self.currentTeamspace?.teamspaceId.uuidString ?? ""
      )
      
    } catch {
      print("error: \(error.localizedDescription)") // FIXME: - 적절한 에러 분기 처리
    }
  }
}
