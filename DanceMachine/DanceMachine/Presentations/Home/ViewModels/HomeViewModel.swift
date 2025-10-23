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
        let userTeamspaces = await fetchUserTeamspace(userId: userId)
        let teamspaces = await fetchTeamspaces(userTeamspaces: userTeamspaces)
        return (userTeamspaces, teamspaces)
    }
    
}


// MARK: - 파이어베이스 관리 메서드
extension HomeViewModel {
    
    
    /// 현재 로그인 유저의 팀스페이스 목록을 전부 가져옵니다.
    /// - Parameters:
    ///     - userID: 현재 로그인 유저의 UUID
    func fetchUserTeamspace(userId: String) async -> [UserTeamspace] {
        do {
            return try await FirestoreManager.shared.fetchAllFromSubcollection(
                under: .users,
                parentId: userId,
                subCollection: .userTeamspace
            )
        } catch {
            print("error: \(error.localizedDescription)") // FIXME: - 적절한 에러 분기처리 추가
            return []
        }
    }
    
    
    /// 현재 로그인 한 유저의 팀 스페이스 서브 컬렉션 아이디를 가져와 팀 스페이스 컬렉션에서 조회 후 리턴하는 메서드입니다.
    /// - Parameters:
    ///     - userTeamspaces: 현재 로그인 유저의 UserTeamspace 서브 컬렉션
    @MainActor
    func fetchTeamspaces(userTeamspaces: [UserTeamspace]) async -> [Teamspace] {
        do {
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
        } catch {
            print("error: \(error.localizedDescription)") // FIXME: - 적절한 에러 처리
            return []
       }
    }
}


// MARK: - 프로젝트 관련 로직
extension HomeViewModel {
    
    
    /// 현재 로그인 유저의 선택된 팀스페이스의 프로젝트 목록을 전부 가져옵니다.
    func fetchCurrentTeamspaceProject() async -> [Project] {
        do {
            return try await FirestoreManager.shared.fetchAll(
                currentTeamspace?.teamspaceId.uuidString ?? "",
                from: .project,                                   // 프로젝트 컬렉션 enum
                where: Project.CodingKeys.teamspaceId.stringValue // 필드명: "teamspaceId"
            )
        } catch {
            print("error: \(error.localizedDescription)")
            return []
        }
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
    
    /// 특정 project_id 에 해당하는 tracks를 반환합니다.
    /// - Parameters:
    ///   - projectId: 필터링할 project_id
    ///   - orderBy: 정렬 기준 (기본값: "created_at")
    ///   - descending: 정렬 방향 (기본값: true)
    /// - Returns: [Track]
    func fetchTracks(
        projectId: String
    ) async throws -> [Tracks] {
        do {
            return try await FirestoreManager.shared.fetchAll(
                projectId,
                from: .tracks,
                where: Project.CodingKeys.projectId.rawValue
            )
        } catch {
            print("error: \(error.localizedDescription)")
            return []
        }
    }
    
}

// MARK: - 곡(Tracks) 관련 로직
extension HomeViewModel {
    
    /// 곡(Tracks) 이름을 수정하는 메서드입니다.
    /// - Parameters:
    ///     - tracksId: 곡(Tracks) Id
    ///     - newTracksName: 새로운 곡(Tracks) 이름
    func updateTracksName(tracksId: String, newTracksName: String) async throws {
        do {
            try await FirestoreManager.shared.updateFields(
                collection: .tracks,
                documentId: tracksId,
                asDictionary: [ Tracks.CodingKeys.trackName.stringValue: newTracksName ]
            )} catch {
                print("error: \(error.localizedDescription)")
            }
    }
    
    
    /// 선택된(펼친) 프로젝트의 트랙만 다시 불러오는 메서드입니다.
    /// - Parameters:
    ///     - choiceSelectedProject: 선택된 Project
    func refreshTracksForSelectedProject(choiceSelectedProject: Project?) async throws -> (UUID, [Tracks]) {
        guard let project = choiceSelectedProject else { throw RefreshError.noSelectedProject }
        
        let id = project.projectId
        let tracks = try await self.fetchTracks(projectId: id.uuidString)
        return (id, tracks)
    }
    
    
    
    /// 곡(Tracks)를 제거하는 메서드입니다.
    /// - Parameters:
    ///     - tracksId: 제거하려는 tracksId
    func removeTracks(tracksId: String) async throws {
        try await FirestoreManager.shared.delete(
            collectionType: .tracks,
            documentID: tracksId
        )
    }
    
    
    /// 곡(Tracks)의 섹션(서브컬렉션)을 조회하는 메서드입니다.
    func fetchSection(tracks: Tracks) async throws -> [Section] {
        do {
            let section: [Section] = try await FirestoreManager.shared.fetchAllFromSubcollection(
                under: .tracks,
                parentId: tracks.tracksId.uuidString,
                subCollection: .section
            )
            return section
        } catch {
            print("error: \(error.localizedDescription)") // FIXME: - 적절한 분기 처리
            return []
        }
    }
    
}
