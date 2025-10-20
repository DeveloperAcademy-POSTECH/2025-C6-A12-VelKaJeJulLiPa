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
    
    /// 유저의 userTeamspace와 실제 Teamspace 목록을 한 번에 로드
    /// 실패 시 빈 배열 반환 + 로그 출력
    func loadUserTeamspacesAndTeamspaces(userId: String)
    async -> (userTeamspaces: [UserTeamspace], teamspaces: [Teamspace]) {
        do {
            let userTeamspaces = try await fetchUserTeamspace(userId: userId)
            let teamspaces = try await fetchTeamspaces(userTeamspaces: userTeamspaces)
            return (userTeamspaces, teamspaces)
        } catch {
            // FIXME: - 적절한 에러 분기/로깅/알림
            print("loadUserTeamspacesAndTeamspaces error: \(error.localizedDescription)")
            return ([], [])
        }
    }
    
}


// MARK: - 파이어베이스 관리 메서드
extension HomeViewModel {
    
    
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
                group.addTask { @MainActor in
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
