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
    
    
    // MARK: - 뷰 모델 주요 메서드
    
    /// 팀스페이스 권한 판별 메서드입니다.
    func isTeamspaceOwner() -> Bool {
        self.currentTeamspace?.ownerId == MockData.userId // FIXME: - MockData를 user_Id로 교체하기 => self.currentTeamspace.teamspaceId
    }
    
    /// 현재 팀스페이스의 전체 멤버의 Id를 조회한 후, Id를 이용하여 Users 컬렉션에서 멤버 정보를 가져오는 메서드입니다.
    func fetchCurrentTeamspaceAllMember() async throws -> [User] {
        do {
            let members: [Members] = try await FirestoreManager.shared.fetchAllFromSubcollection(
                under: .teamspace,
                parentId: self.currentTeamspace?.teamspaceId.uuidString ?? "",
                subCollection: .members
            )
            
            var userIds: [String] = []
            for member in members {
                userIds.append(member.userId)
            }
            
            var users: [User] = []
            for id in userIds {
                users.append(try await FirestoreManager.shared.get(id, from: .users))
            }
            return users
        } catch {
            print("error: \(error.localizedDescription)") // FIXME: - 에러에 맞게 로직 수정
            return []
        }
    }
    
    /// 특정 멥버를 팀 스페이스에서 제거하는 메서드 입니다.
    /// - Parameters:
    ///     - teamspaceId: 팀 스페이스 Id
    ///     - userId: 제거하려는 유저 Id
    func removingTeamspaceMember(userId: String) async throws {
        try await FirestoreManager.shared.deleteFromSubcollection(
            under: .teamspace,
            parentId: currentTeamspace?.teamspaceId.uuidString ?? "",
            subCollection: .members,
            target: userId
        )
    }
    
    
    /// 팀 스페이스 나가기
    func leaveTeamspace() async throws {
        do {
            try await self.removeUserFromCurrentTeamspace(userId: MockData.userId)
            let userTeamspaces = try await self.fetchUserTeamspace(userId: MockData.userId)
            let loadTeamspaces = try await self.fetchTeamspaces(userTeamspaces: userTeamspaces)
            
            if let firstTeamspace = loadTeamspaces.first {
                await MainActor.run {
                    self.fetchCurrentTeamspace(teamspace: firstTeamspace)
                }
            }
        } catch {
            print("error: \(error.localizedDescription)") // FIXME: - 에러에 맞게 로직 수정
        }
    }
    
    
    /// 팀원 내보내기 + 팀 스페이스 현재 멤버 새로고침
    func removeTeamMemberAndReload(userId: String) async throws -> [User] {
        do {
            try await self.removingTeamspaceMember(userId: userId)
            return try await self.fetchCurrentTeamspaceAllMember()
        } catch {
            print("error: \(error.localizedDescription)") // FIXME: - 에러에 맞게 로직 수정
            return []
        }
    }
    
    
    /// 팀 스페이스 이름 수정하기 + 팀 스페이스 새로 고침
    func renameCurrentTeamspaceAndReload(editedName: String) async throws {
        do {
            try await self.updateTeamspaceName(
                teamspaceId: self.currentTeamspace?.teamspaceId.uuidString ?? "",
                newTeamspaceName: editedName
            )
            
            // 조회 후 값 다시 넣어주기
            FirebaseAuthManager.shared.currentTeamspace = try await FirestoreManager.shared.get(
                self.currentTeamspace?.teamspaceId.uuidString ?? "",
                from: .teamspace
            )
        } catch {
            print("error: \(error.localizedDescription)") // FIXME: - 에러에 맞게 로직 수정
        }
    }
}



// MARK: - 파이어베이스 관리 메서드
extension TeamspaceSettingViewModel {
    
    /// FirebaseAuthManager의 현재 팀 스페이스를 교체하는 메서드 입니다.
    func fetchCurrentTeamspace(teamspace: Teamspace) {
        FirebaseAuthManager.shared.currentTeamspace = teamspace
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
    
    
    /// 사용자가 "현재 팀스페이스"에서 탈퇴하며 teamspace/members 와 users/userTeamspace 모두에서 참조를 제거
    /// - Parameters:
    ///     - userId: 유저 아이디
    func removeUserFromCurrentTeamspace(userId: String) async throws {
        // teamspace 서브컬렉션에서 유저를 제거
        try await FirestoreManager.shared.deleteFromSubcollection(
            under: .teamspace,
            parentId: self.currentTeamspace?.teamspaceId.uuidString ?? "",
            subCollection: .members,
            target: userId
        )
        
        // users 서브컬렉션에서 teamspace를 제거
        try await FirestoreManager.shared.deleteFromSubcollection(
            under: .users,
            parentId: userId,
            subCollection: .userTeamspace,
            target: self.currentTeamspace?.teamspaceId.uuidString ?? ""
        )
    }
    
    
    // FIXME: - 로직 수정 => 팀 스페이스에 있는 모든 유저의 서브컬렉션에서 팀 스페이스를 제거 해야함.
    /// 팀 스페이스를 제거하는 메서드입니다.
    /// - Parameters:
    ///     - userId: 유저 아이디
    func removeTeamspace(userId: String) async throws {
        try await FirestoreManager.shared.deleteAllDocumentsInSubcollection(under: .teamspace, parentId: self.currentTeamspace?.teamspaceId.uuidString ?? "", subCollection: .members)
        try await FirestoreManager.shared.delete(collectionType: .teamspace, documentID: self.currentTeamspace?.teamspaceId.uuidString ?? "") // 팀 스페이스 문서 제거
        try await FirestoreManager.shared.deleteFromSubcollection(under: .users, parentId: userId, subCollection: .userTeamspace, target: self.currentTeamspace?.teamspaceId.uuidString ?? "")// 유저 팀 서브 컬렉션 스페이스에서 팀 스페이스를 제거
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
