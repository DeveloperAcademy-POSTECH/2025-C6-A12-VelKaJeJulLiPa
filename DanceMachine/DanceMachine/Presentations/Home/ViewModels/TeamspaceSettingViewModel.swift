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
    
    
    /// 특정 멥버를 팀 스페이스에서 제거하는 메서드 입니다.
    /// - Parameters:
    ///     - teamspaceId: 팀 스페이스 Id
    ///     - userId: 제거하려는 유저 Id
    func removingTeamspaceMember(teamspaceId: String, userId: String) async throws {
        try await FirestoreManager.shared.deleteFromSubcollection(
            under: .teamspace,
            parentId: teamspaceId,
            subCollection: .members,
            target: userId
        )
    }
    
    
    /// 팀 스페이스를 제거하는 메서드입니다.
    /// - Parameters:
    ///     - userId: 유저 아이디
    ///     - teamspaceId: 팀 스페이스 Id
    func removeTeamspace(userId: String, teamspaceId: String) async throws {
        try await FirestoreManager.shared.deleteAllDocumentsInSubcollection(under: .teamspace, parentId: teamspaceId, subCollection: .members)
        try await FirestoreManager.shared.delete(collectionType: .teamspace, documentID: teamspaceId) // 팀 스페이스 문서 제거
        try await FirestoreManager.shared.deleteFromSubcollection(under: .users, parentId: userId, subCollection: .userTeamspace, target: teamspaceId)// 유저 팀 서브 컬렉션 스페이스에서 팀 스페이스를 제거
    }
    
    
    /// 현재 로그인 유저의 팀스페이스 목록을 전부 가져옵니다.
    /// - Parameters:
    ///     - userID: 현재 로그인 유저의 UUID
    func fetchUserTeamspace(userId: String) async throws -> [UserTeamspace] {
        return try await FirestoreManager.shared.fetchAllFromSubcollection(
            under: .users,
            parentId: userId,
            subCollection: .userTeamspace
        )
    }
    
    /// 현재 로그인 한 유저의 팀 스페이스 서브 컬렉션 아이디를 가져와 팀 스페이스 컬렉션에서 조회 후 리턴하는 메서드입니다.
    /// - Parameters:
    ///     - userTeamspaces: 현재 로그인 유저의 UserTeamspace 서브 컬렉션
    @MainActor
    func fetchTeamspaces(userTeamspaces: [UserTeamspace]) async throws -> [Teamspace] {
        // 순서 보존하며 중복 제거
        var seen = Set<String>()
        let ids = userTeamspaces.compactMap { ut -> String? in
            if seen.insert(ut.teamspaceId).inserted { return ut.teamspaceId }
            return nil
        }
        guard !ids.isEmpty else { return [] }

        struct Indexed { let index: Int; let item: Teamspace }

        let fetched: [Indexed] = try await withThrowingTaskGroup(of: Indexed.self) { group in
            for (idx, id) in ids.enumerated() {
                group.addTask {
                    let t: Teamspace = try await FirestoreManager.shared.get(id, from: .teamspace)
                    return Indexed(index: idx, item: t)
                }
            }
            var acc: [Indexed] = []
            for try await v in group { acc.append(v) }
            return acc
        }
        return fetched.sorted { $0.index < $1.index }.map(\.item)
    }
}
