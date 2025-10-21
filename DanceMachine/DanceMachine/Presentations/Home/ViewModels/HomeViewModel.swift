//
//  HomeViewModel.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import Foundation

@Observable
final class HomeViewModel {
    
     var currentTeamspace: Teamspace? { FirebaseAuthManager.shared.currentTeamspace }
    
    
    /// FirebaseAuthManager의 현재 팀 스페이스를 교체하는 메서드 입니다.
    func fetchCurrentTeamspace(teamspace: Teamspace) {
        FirebaseAuthManager.shared.currentTeamspace = teamspace
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


// MARK: - 프로젝트 관련 로직
extension HomeViewModel {
    
    
    /// 현재 로그인 유저의 선택된 팀스페이스의 프로젝트 목록을 전부 가져옵니다.
    func fetchCurrentTeamspaceProject() async throws -> [Project] {
        // TODO: 이 메서드를 teamspaceId를 파라미터로 받아서, project컬렉션에 있는 모든 데이터중에 필드의 teamspaceId가 같은 것을 찾는 메서드를 만들어야함.
        return try await FirestoreManager.shared.fetchAll(
            currentTeamspace?.teamspaceId.uuidString ?? "",
            from: .project,                                   // 프로젝트 컬렉션 enum
            where: Project.CodingKeys.teamspaceId.stringValue // 필드명: "teamspaceId"
        )
    }
    
    /// 프로젝트를 제거하는 메서드입니다.
    /// - Parameters:
    ///     - projectId: 프로젝트 Id
    func removeProject(projectId: String) async throws {
        do {
            try await FirestoreManager.shared.delete(collectionType: .project, documentID: projectId)
        } catch {
            print("error: \(error.localizedDescription)") // FIXME: - 적절한 에러 처리
        }
    }
    
    /// 프로젝트 이름을 수정하는 메서드입니다.
    /// - Parameters:
    ///     - projectId: 프로젝트 Id
    ///     - newProjectName: 새로운 프로젝트 이름
    func updateProjectName(projectId: String, newProjectName: String) async throws {
        do {
            try await FirestoreManager.shared.updateFields(
                collection: .project,
                documentId: projectId,
                asDictionary: [ Project.CodingKeys.projectName.stringValue: newProjectName ]
            )} catch {
                print("error: \(error.localizedDescription)")
            }
    }
    
    
}

