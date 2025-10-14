//
//  TeamspaceSettingViewModel.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/12/25.
//

import Foundation

@Observable
final class TeamspaceSettingViewModel {
    
    var currentTeamspace: Teamspace? { FirebaseAuthManager.shared.currentTeamspace }
    
    
    /// FirebaseAuthManager의 현재 팀 스페이스를 교체하는 메서드 입니다.
    func fetchCurrentTeamspace(teamspace: Teamspace) {
        FirebaseAuthManager.shared.currentTeamspace = teamspace
    }
    
    /// 팀 스페이스 서브 컬렉션 멤버를 전체 조회하는 메서드 입니다.
    /// - Parameters:
    ///     - teamspaceId: 팀 스페이스 Id
    func fetchTeamspaceMembers(teamspaceId: String) async throws -> [Members] {
        return try await FirestoreManager.shared.fetchAllFromSubcollection(
            under: .teamspace,
            parentId: teamspaceId,
            subCollection: .members
        )
    }
    
    
    /// 팀 스페이스 이름을 업데이트 하는 메서드 입니다.
    /// - Parameters:
    ///     - teamspaceId: 팀 스페이스 Id (팀 스페이스 식별)
    ///     - newTeamspaceName: 변경 이름
    func updateTeamspaceName(teamspaceId: String, newTeamspaceName: String) async throws {
        try await FirestoreManager.shared.updateFields(
            collection: .teamspace,
            documentId: teamspaceId,
            asDictionary: [ Teamspace.CodingKeys.teamspaceName.stringValue: newTeamspaceName ]
        )
    }
    
    
    /// 유저 아이디 배열을 받아, 유저 이름들을 검색하는 메서드 입니다.
    func fetchUserNamesInOrder(userIds: [String]) async throws -> [User] {
        var users: [User] = []
        
        for id in userIds {
            users.append(try await FirestoreManager.shared.get(id, from: .users))
        }
        
        return users
    }
}
