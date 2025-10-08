//
//  CreateTeamspaceViewModel.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/8/25.
//

import Foundation

@Observable
final class CreateTeamspaceViewModel {
    
    /// 팀 스페이스 생성 메서드입니다.
    /// - userId: userId -> ownerId, 팀 스페이스 owner는 현재 로그인 유저
    /// - teamspaceName: 팀 스페이스 이름
    func createTeamsapce(userId: String, teamspaceName: String) async throws {
        let teamspace: Teamspace = .init(
            teamspaceId: UUID(),
            ownerId: userId,
            teamspaceName: teamspaceName
        )
        try await FirestoreManager.shared.create(teamspace)
    }
}
