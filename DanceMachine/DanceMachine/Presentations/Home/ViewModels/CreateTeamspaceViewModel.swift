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
    func createTeamsapce(userId: String, teamspaceName: String) async throws -> String {
        let teamspace: Teamspace = .init(
            teamspaceId: UUID(),
            ownerId: userId,
            teamspaceName: teamspaceName
        )
        try await FirestoreManager.shared.create(teamspace)
        
        let teamspaceId = teamspace.teamspaceId
        return teamspaceId.uuidString
    }
    
    /// 현재 로그인 된 유저의 서브 컬렉션 UserTeamspace 추가 메서드 입니다.
    /// teamspaceId: 팀 스페이스 documentId
    func includeUserTeamspace(teamspaceId: String) async throws {
        try await FirestoreManager.shared.writeToSubcollection(
            UserTeamspace(teamspaceId: teamspaceId),
            under: .users,
            parentId: "4150C2CF-27DD-4B32-9313-0454258814BF", // FIXME: - 유저 아이디로 변경
            subCollection: .userTeamspace,
            strategy: .join
        )
    }
}
