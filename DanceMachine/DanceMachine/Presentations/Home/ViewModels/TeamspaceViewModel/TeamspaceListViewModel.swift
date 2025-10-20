//
//  TeamspaceListViewModel.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/12/25.
//

import Foundation

@Observable
final class TeamspaceListViewModel {
    
    
    var currentTeamspace: Teamspace? { FirebaseAuthManager.shared.currentTeamspace }
    
    
    /// FirebaseAuthManager의 현재 팀 스페이스를 교체하는 메서드 입니다.
    func fetchCurrentTeamspace(teamspace: Teamspace) {
        FirebaseAuthManager.shared.currentTeamspace = teamspace
    }
    
    // 주어진 유저의 팀스페이스 전체를 로드합니다.
    ///
    /// 이 메서드는 다음 단계를 한 번에 수행합니다:
    /// 1) `users/{userId}/userTeamspace` 서브컬렉션을 조회하여 팀스페이스 ID 목록을 가져옵니다.
    /// 2) 가져온 ID들을 기반으로 `teamspace` 컬렉션에서 실제 `Teamspace` 문서를 병렬로 조회합니다.
    /// 3) 중복 ID를 제거하고, 원래 순서를 보존하여 결과를 반환합니다.
    ///
    /// - Parameter userId: 팀스페이스를 조회할 대상 유저의 UUID(문자열).
    /// - Returns: 해당 유저가 속한 `Teamspace` 배열. 결과는 원래 서브컬렉션 순서를 최대한 보존합니다.
    /// - Throws: 파이어스토어 조회 실패 등 비동기 작업 중 발생한 에러를 던질 수 있습니다.
    /// - Note: 내부적으로 동시성(`withThrowingTaskGroup`)을 사용해 개별 팀스페이스 문서를 병렬 조회합니다.
    func loadTeamspacesForUser(userId: String) async throws -> [Teamspace] {
        do {
            let userTeamspaces = try await self.fetchUserTeamspace(userId: userId)
            return try await self.fetchTeamspaces(userTeamspaces: userTeamspaces)
        } catch {
            print("error: \(error.localizedDescription)") // FIXME: - 적절한 에러 분기 처리
            return []
        }
    }

}


extension TeamspaceListViewModel {
    
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
