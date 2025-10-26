//
//  CreateTeamspaceViewModel.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/8/25.
//

import Foundation

@Observable
final class CreateTeamspaceViewModel {
    
    /// 팀스페이스 생성 + 소유자 멤버 추가 + 사용자 userTeamspace 등록까지 한 번에
    /// - Parameters:
    ///     - teamspaceNameText: 팀 스페이스 이름
    func createTeamspaceWithInitialMembership(teamspaceNameText: String) async throws {
        do {
            let teamspaceId = try await self.createTeamsapce(
                userId: FirebaseAuthManager.shared.userInfo?.userId ?? "",
                teamspaceName: teamspaceNameText
            )
            
            try await self.createTeamspaceMember(
                userId: FirebaseAuthManager.shared.userInfo?.userId ?? "",
                teamspaceId: teamspaceId
            )
            try await self.includeUserTeamspace(teamspaceId: teamspaceId)
        } catch {
            print("error: \(error.localizedDescription)") // FIXME: - 에러 분기 처리 추가하기
        }
    }
}


// MARK: - 파이어베이스 관리 메서드
extension CreateTeamspaceViewModel {
    
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
    
    /// 팀 스페이스 멤버 서브 컬렉션 생성 메서드 입니다.
    /// - Parameters:
    ///     - userId: 생성 유저의 UUID
    ///     - teamspaceId: 어떤 팀 스페이스인지 식별하기 위한 팀 스페이스 Id
    ///
    /// 팀 스페이스 생성 시, 팀 스페이스 소유자는 자동으로 멤버로 추가 되기 위해 구현
    func createTeamspaceMember(userId: String, teamspaceId: String) async throws {
        try await FirestoreManager.shared.createToSubcollection(
            Members(userId: userId),
            under: .teamspace,
            parentId: teamspaceId,
            subCollection: .members,
            strategy: .join
        )
    }
    
    /// 현재 로그인 된 유저의 서브 컬렉션 UserTeamspace 추가 메서드 입니다.
    /// teamspaceId: 팀 스페이스 documentId
    func includeUserTeamspace(teamspaceId: String) async throws {
        try await FirestoreManager.shared.createToSubcollection(
            UserTeamspace(teamspaceId: teamspaceId),
            under: .users,
            parentId: FirebaseAuthManager.shared.userInfo?.userId ?? "",
            subCollection: .userTeamspace,
            strategy: .join
        )
    }
}
