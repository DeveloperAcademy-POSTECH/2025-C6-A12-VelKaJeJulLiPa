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
            let project: Project = .init(
                projectId: UUID(),
                teamspaceId: self.currentTeamspace?.teamspaceId.uuidString ?? "",
                creatorId: FirebaseAuthManager.shared.userInfo?.userId ?? "",
                projectName: projectName
            )
            try await FirestoreManager.shared.create(project)
        } catch {
            print("error: \(error.localizedDescription)") // FIXME: - 적절한 에러 분기 처리
        }
    }
}
