//
//  HomeViewModel.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import Foundation
import FirebaseAuth
import SwiftUI
import UserNotifications


/// 홈 화면의 뷰모델로, 팀스페이스, 프로젝트, 트랙 관련 상태와 로직을 관리합니다.
@Observable
final class HomeViewModel {

    /// 현재 선택된 팀스페이스 (FirebaseAuthManager의 currentTeamspace와 연동)
    var currentTeamspace: Teamspace? { FirebaseAuthManager.shared.currentTeamspace }

    /// 유저가 속한 팀스페이스 목록 (읽기 전용)
    private(set) var userTeamspaces: [UserTeamspace] = []

    /// 현재 선택된 프로젝트 (읽기 전용)
    private(set) var selectedProject: Project?

    /// 프로젝트 목록과 편집 상태를 관리하는 구조체
    struct ProjectListState {
        /// 프로젝트 목록 헤더 타이틀
        var headerTitle: String = "프로젝트 목록"
        /// 프로젝트 배열
        var projects: [Project] = []
        /// 프로젝트 행의 상태 (보기/편집 등)
        var rowState: ProjectRowState = .viewing
        /// 편집 중인 프로젝트 ID
        var editingID: UUID?
        /// 편집 중인 텍스트
        var editText: String = ""
        /// 확장된 프로젝트 ID
        var expandedID: UUID?
    }

    /// 트랙 목록과 편집 상태를 관리하는 구조체
    struct TracksState {
        /// 트랙 행의 상태 (보기/편집 등)
        var rowState: TracksRowState = .viewing
        /// 편집 중인 트랙 ID
        var editingID: UUID?
        /// 편집 중인 텍스트
        var editText: String = ""
        /// 프로젝트별 트랙 목록 딕셔너리
        var byProject: [UUID: [Tracks]] = [:]
        /// 로딩 중인 프로젝트 ID 집합
        var loading: Set<UUID> = []
        /// 에러 메시지 딕셔너리 (프로젝트 ID별)
        var error: [UUID: String] = [:]
    }

    /// 팀스페이스 UI 상태를 묶은 구조체
    struct TeamspaceUIState {
        /// 팀스페이스 상태 (empty / nonEmpty)
        var state: TeamspaceState = .empty
        /// 전체 팀스페이스 목록
        var list: [Teamspace] = []
        /// 헤더 로딩 상태
        var isLoading: Bool = false
        /// 최초 초기화 여부
        var didInitialize: Bool = false
    }

    /// 팀스페이스 관련 상태
    var teamspace = TeamspaceUIState()
    /// 프로젝트 관련 상태
    var project = ProjectListState()
    /// 트랙 관련 상태
    var tracks  = TracksState()

    /// 프로젝트 상태에 대한 바인딩을 생성합니다.
    /// - Parameter kp: 프로젝트 상태의 WritableKeyPath
    /// - Returns: 해당 상태에 대한 Binding
    func plBinding<T>(_ kp: WritableKeyPath<ProjectListState, T>) -> Binding<T> {
        Binding(
            get: { self.project[keyPath: kp] },
            set: { self.project[keyPath: kp] = $0 }
        )
    }

    /// 트랙 상태에 대한 바인딩을 생성합니다.
    /// - Parameter kp: 트랙 상태의 WritableKeyPath
    /// - Returns: 해당 상태에 대한 Binding
    func trBinding<T>(_ kp: WritableKeyPath<TracksState, T>) -> Binding<T> {
        Binding(
            get: { self.tracks[keyPath: kp] },
            set: { self.tracks[keyPath: kp] = $0 }
        )
    }

    /// 팀스페이스 UI 상태에 대한 바인딩을 생성합니다.
    /// - Parameter kp: 팀스페이스 UI 상태의 WritableKeyPath
    /// - Returns: 해당 상태에 대한 Binding
    func tsBinding<T>(_ kp: WritableKeyPath<TeamspaceUIState, T>) -> Binding<T> {
        Binding(
            get: { self.teamspace[keyPath: kp] },
            set: { self.teamspace[keyPath: kp] = $0 }
        )
    }

    /// 유저 정보를 FirebaseAuthManager를 통해 비동기적으로 가져옵니다.
    @MainActor
    func fetchUserInfo() async throws {
        do {
            print("유저 정보를 로드합니다. (fetchUserInfo 시작)")
            try await FirebaseAuthManager.shared.fetchUserInfo(for: FirebaseAuthManager.shared.user?.uid ?? "")
            print("유저 정보 로드가 완료되었습니다. (fetchUserInfo 종료)")
        } catch {
            print("유저 정보 로드 중 오류가 발생했습니다. (fetchUserInfo 실패): \(error.localizedDescription)")
        }
    }

    /// 팀스페이스 목록을 새로고침합니다.
    /// - Note: 이미 로딩 중이면 중복 실행을 방지합니다.
    @MainActor
    func reloadTeamspaces() async {
        print("팀스페이스 목록 새로고침을 진행합니다. (reloadTeamspaces 시작)")
        if teamspace.isLoading {
            print("팀스페이스 새로고침이 이미 진행 중입니다. 중복 실행을 방지하고 종료합니다. (reloadTeamspaces 중단)")
            return
        }
        teamspace.isLoading = true
        defer { teamspace.isLoading = false }

        self.userTeamspaces = await fetchUserTeamspace()
        let loaded = await fetchTeamspaces()
        self.teamspace.list = loaded
        self.teamspace.state = loaded.isEmpty ? .empty : .nonEmpty
        print("팀스페이스 목록 새로고침이 완료되었습니다. 로드된 개수: \(loaded.count) (reloadTeamspaces 종료)")
    }

    /// 앱 최초 실행 또는 재시작 시 기본 팀스페이스를 설정합니다.
    @MainActor
    func ensureTeamspaceInitialized() async {
        print("기본 팀스페이스 초기화를 진행합니다. (ensureTeamspaceInitialized 시작)")
            await reloadTeamspaces()
            if let first = teamspace.list.first, currentTeamspace == nil {
                setCurrentTeamspace(first)
            }
            // teamspace.didInitialize = true
            print("기본 팀스페이스 초기화가 완료되었습니다. 현재 선택: \(self.currentTeamspace?.teamspaceName ?? "없음") (ensureTeamspaceInitialized 종료)")
    }

    /// 현재 팀스페이스 이름 반환
    var currentTeamspaceName: String {
        currentTeamspace?.teamspaceName ?? ""
    }

    /// 유저가 속한 팀스페이스 목록을 Firestore에서 비동기적으로 가져옵니다.
    /// - Returns: 유저 팀스페이스 배열
    func fetchUserTeamspace() async -> [UserTeamspace] {
        do {
            print("유저가 속한 팀스페이스 목록을 가져옵니다. (fetchUserTeamspace 시작)")
            let result: [UserTeamspace] = try await FirestoreManager.shared.fetchAllFromSubcollection(
                under: .users,
                parentId: FirebaseAuthManager.shared.userInfo?.userId ?? "",
                subCollection: .userTeamspace
            )
            print("유저 팀스페이스 목록 조회가 완료되었습니다. (fetchUserTeamspace 종료)")
            return result
        } catch {
            print("유저 팀스페이스 목록 조회 중 오류가 발생했습니다. (fetchUserTeamspace 실패): \(error.localizedDescription)")
            return []
        }
    }

    /// 팀스페이스 목록을 Firestore에서 비동기적으로 가져옵니다.
    /// - Returns: 로드된 팀스페이스 배열
    func fetchTeamspaces() async -> [Teamspace] {
        print("팀스페이스 목록을 가져옵니다. (fetchTeamspaces 시작)")
        do {
            var seen = Set<String>()
            let ids = self.userTeamspaces.compactMap { ut -> String? in
                if seen.insert(ut.teamspaceId).inserted { return ut.teamspaceId }
                return nil
            }
            guard !ids.isEmpty else {
                print("팀스페이스 ID가 비어 있어 조회를 종료합니다. (fetchTeamspaces 종료)")
                return []
            }

            struct Indexed { let index: Int; let item: Teamspace }

            let fetched: [Indexed] = try await withThrowingTaskGroup(of: Indexed.self) { group in
                for (idx, id) in ids.enumerated() {
                    group.addTask {
                        let teamspace: Teamspace = try await FirestoreManager.shared.get(id, from: .teamspace)
                        return Indexed(index: idx, item: teamspace)
                    }
                }
                var acc: [Indexed] = []
                for try await v in group { acc.append(v) }
                return acc
            }
            print("팀스페이스 목록 조회가 완료되었습니다. 총 \(fetched.count)개 (fetchTeamspaces 종료)")
            return fetched.sorted { $0.index < $1.index }.map(\.item)
        } catch {
            print("팀스페이스 목록 조회 중 오류가 발생했습니다. (fetchTeamspaces 실패): \(error.localizedDescription)")
            return []
        }
    }

    /// 현재 팀스페이스를 설정합니다.
    /// - Parameter teamspace: 설정할 팀스페이스
    func setCurrentTeamspace(_ teamspace: Teamspace) {
        print("현재 팀스페이스를 설정합니다: \(teamspace.teamspaceName) (setCurrentTeamspace 시작)")
        FirebaseAuthManager.shared.currentTeamspace = teamspace
        print("현재 팀스페이스 설정이 완료되었습니다. (setCurrentTeamspace 종료)")
    }

    /// 팀스페이스 선택 시 호출, 관련 UI 상태를 초기화하고 프로젝트를 로드합니다.
    /// - Parameter teamspace: 선택된 팀스페이스
    @MainActor
    func selectTeamspace(_ teamspace: Teamspace) async {
        print("팀스페이스 선택 처리 및 관련 데이터 로드를 시작합니다: \(teamspace.teamspaceName) (selectTeamspace 시작)")
        setCurrentTeamspace(teamspace)
        project.headerTitle = "프로젝트 목록"
        project.expandedID = nil
        selectedProject = nil
        tracks.rowState = .viewing
        tracks.editingID = nil
        tracks.editText = ""
        tracks.byProject.removeAll()
        tracks.loading.removeAll()
        tracks.error.removeAll()
        print("프로젝트 목록 로드를 시작합니다. (selectTeamspace 내부)")
        _ = await fetchCurrentTeamspaceProject()
        print("팀스페이스 선택 처리 및 데이터 로드가 완료되었습니다. (selectTeamspace 종료)")
    }
}

// MARK: - 프로젝트 관리
extension HomeViewModel {
    
    
    
    /// 팀스페이스 교체/삭제 후 프로젝트 헤더 및 목록 리로드
    @MainActor
    func reloadProjectsAfterTeamspaceChange() async {
        print("팀스페이스 변경 감지: 프로젝트 헤더/목록 리로드를 시작합니다. (reloadProjectsAfterTeamspaceChange 시작)")

        // 팀 스페이스 상태 변경
        if FirebaseAuthManager.shared.currentTeamspace == nil {
            teamspace.state = .empty
        } else {
            teamspace.state = .nonEmpty
        }
        
        // 프로젝트/트랙 관련 UI 초기화
        project.headerTitle = "프로젝트 목록"
        project.expandedID = nil
        selectedProject = nil

        tracks.rowState = .viewing
        tracks.editingID = nil
        tracks.editText = ""
        tracks.byProject.removeAll()
        tracks.loading.removeAll()
        tracks.error.removeAll()

        // 현재 팀스페이스가 있다면 그 기준으로 프로젝트 재조회
        let list = await fetchCurrentTeamspaceProject()

        // 프로젝트가 없어도 헤더는 "프로젝트 목록"로 유지
        if list.isEmpty {
            print("현재 팀스페이스에 프로젝트가 없습니다. 헤더를 기본값으로 유지합니다.")
            project.headerTitle = "프로젝트 목록"
        }

        print("팀스페이스 변경 감지: 프로젝트 헤더/목록 리로드가 완료되었습니다. (reloadProjectsAfterTeamspaceChange 종료)")
    }
    
    
    /// 팀스페이스가 삭제되어 currentTeamspace 가 nil 인 상황 처리
    @MainActor
    func handleTeamspaceDeleted() async {
        print("팀스페이스 삭제 감지: 프로젝트/헤더 초기화를 시작합니다. (handleTeamspaceDeleted 시작)")
        teamspace.state = .empty
        await reloadProjectsAfterTeamspaceChange()
        print("팀스페이스 삭제 감지: 초기화가 완료되었습니다. (handleTeamspaceDeleted 종료)")
    }
    
    
    /// 현재 팀스페이스의 프로젝트 목록을 Firestore에서 비동기적으로 가져옵니다.
    /// - Returns: 프로젝트 배열
    @discardableResult
    func fetchCurrentTeamspaceProject() async -> [Project] {
        print("현재 팀스페이스의 프로젝트 목록을 가져옵니다. (fetchCurrentTeamspaceProject 시작)")
        do {
            let list: [Project] = try await FirestoreManager.shared.fetchAll(
                currentTeamspace?.teamspaceId.uuidString ?? "",
                from: .project,
                where: Project.CodingKeys.teamspaceId.stringValue
            )
            print("프로젝트 목록 \(list.count)개를 가져왔습니다.")
            self.project.projects = list
            print("프로젝트 목록 조회가 완료되었습니다. (fetchCurrentTeamspaceProject 종료)")
            return list
        } catch {
            print("프로젝트 목록 조회 중 오류가 발생했습니다. (fetchCurrentTeamspaceProject 실패): \(error.localizedDescription)")
            self.project.projects = []
            return []
        }
    }

    /// 프로젝트 편집을 커밋합니다. (이름 변경 후 목록 갱신)
    func commitProjectEdit() async {
        print("프로젝트 편집 커밋을 시작합니다. (commitProjectEdit 시작)")
        guard case .editing(.update) = project.rowState,
              let pid = project.editingID else { return }
        let name = project.editText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        do {
            try await updateProjectName(projectId: pid.uuidString, newProjectName: name)
            let refreshed = await fetchCurrentTeamspaceProject()
            if let sp = selectedProject, sp.projectId == pid,
               let updated = refreshed.first(where: { $0.projectId == pid }) {
                project.headerTitle = updated.projectName
                selectedProject = updated
            }
            project.editingID = nil
            project.editText = ""
            project.rowState = .viewing
            print("프로젝트 편집 커밋이 완료되었습니다. (commitProjectEdit 종료)")
        } catch {
            print("프로젝트 편집 커밋 중 오류가 발생했습니다. (commitProjectEdit 실패): \(error.localizedDescription)")
        }
    }

    /// 프로젝트 이름을 Firestore에 업데이트합니다.
    func updateProjectName(projectId: String, newProjectName: String) async throws {
        print("프로젝트 이름 업데이트를 시작합니다. 대상: \(projectId), 새 이름: \(newProjectName) (updateProjectName 시작)")
        try await FirestoreManager.shared.updateFields(
            collection: .project,
            documentId: projectId,
            asDictionary: [ Project.CodingKeys.projectName.stringValue: newProjectName ]
        )
        print("프로젝트 이름 업데이트가 완료되었습니다. (updateProjectName 종료)")
    }

    /// 프로젝트를 Firestore에서 삭제합니다.
    func removeProject(projectId: String) async throws {
        print("프로젝트 삭제를 시작합니다. 대상: \(projectId) (removeProject 시작)")
        try await FirestoreManager.shared.delete(collectionType: .project, documentID: projectId)
        print("프로젝트 삭제가 완료되었습니다. (removeProject 종료)")
    }

    /// 프로젝트 확장 토글
    func toggleExpand(_ project: Project) {
        print("프로젝트 확장 토글을 시작합니다. 대상: \(project.projectName) (toggleExpand 시작)")
        let id = project.projectId
        if self.project.expandedID == id {
            print("프로젝트를 접습니다. (toggleExpand 접기)")
            self.project.expandedID = nil
            self.selectedProject = nil
            self.project.headerTitle = "프로젝트 목록"
            tracks.rowState = .viewing
            tracks.editingID = nil
            tracks.editText = ""
        } else {
            print("프로젝트를 펼칩니다. (toggleExpand 펼치기)")
            self.project.expandedID = id
            self.selectedProject = project
            self.project.headerTitle = project.projectName
            if tracks.byProject[id] == nil { loadTracks(for: id) }
        }
        print("프로젝트 확장 토글이 완료되었습니다. (toggleExpand 종료)")
    }

    /// 주어진 프로젝트가 확장 상태인지 여부
    func isExpanded(_ project: Project) -> Bool {
        self.project.expandedID == project.projectId
    }
}

// MARK: - 트랙 관리
extension HomeViewModel {
    /// 특정 프로젝트의 트랙을 비동기적으로 로드합니다.
    func loadTracks(for projectID: UUID) {
        print("특정 프로젝트의 트랙 로드를 시작합니다. projectID: \(projectID) (loadTracks 시작)")
        if tracks.loading.contains(projectID) {
            print("이미 해당 프로젝트의 트랙을 로딩 중입니다. 중복 실행을 방지하고 종료합니다. (loadTracks 중단)")
            return
        }
        tracks.loading.insert(projectID)
        tracks.error[projectID] = nil
        Task {
            do {
                let list = try await fetchTracks(projectId: projectID.uuidString)
                print("트랙 목록 \(list.count)개를 가져왔습니다.")
                await MainActor.run {
                    self.tracks.byProject[projectID] = list
                    self.tracks.loading.remove(projectID)
                    print("특정 프로젝트의 트랙 로드가 완료되었습니다. (loadTracks 종료)")
                }
            } catch {
                print("트랙 로드 중 오류가 발생했습니다. (loadTracks 실패): \(error.localizedDescription)")
                await MainActor.run {
                    self.tracks.error[projectID] = error.localizedDescription
                    self.tracks.loading.remove(projectID)
                }
            }
        }
    }

    /// 프로젝트 ID로부터 트랙 목록을 Firestore에서 비동기적으로 가져옵니다.
    func fetchTracks(projectId: String) async throws -> [Tracks] {
        print("프로젝트 ID로부터 트랙 목록을 가져옵니다. 대상: \(projectId) (fetchTracks 시작)")
        do {
            let result: [Tracks] = try await FirestoreManager.shared.fetchAll(
                projectId,
                from: .tracks,
                where: Project.CodingKeys.projectId.rawValue
            )
            print("트랙 목록 조회가 완료되었습니다. (fetchTracks 종료)")
            return result
        } catch {
            print("트랙 목록 조회 중 오류가 발생했습니다. (fetchTracks 실패): \(error.localizedDescription)")
            return []
        }
    }

    /// 트랙 편집을 커밋합니다. (이름 변경 후 목록 갱신)
    func commitTrackEdit() async {
        print("트랙 편집 커밋을 시작합니다. (commitTrackEdit 시작)")
        guard case .editing(.update) = tracks.rowState,
              let tid = tracks.editingID,
              let project = selectedProject else { return }
        let name = tracks.editText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        do {
            try await updateTracksName(tracksId: tid.uuidString, newTracksName: name)
            if let fresh = try? await fetchTracks(projectId: project.projectId.uuidString) {
                await MainActor.run { self.tracks.byProject[project.projectId] = fresh }
            }
            tracks.editingID = nil
            tracks.editText = ""
            tracks.rowState = .viewing
            print("트랙 편집 커밋이 완료되었습니다. (commitTrackEdit 종료)")
        } catch {
            print("트랙 편집 커밋 중 오류가 발생했습니다. (commitTrackEdit 실패): \(error.localizedDescription)")
        }
    }

    /// 트랙 이름을 Firestore에 업데이트합니다.
    func updateTracksName(tracksId: String, newTracksName: String) async throws {
        print("트랙 이름 업데이트를 시작합니다. 대상: \(tracksId), 새 이름: \(newTracksName) (updateTracksName 시작)")
        try await FirestoreManager.shared.updateFields(
            collection: .tracks,
            documentId: tracksId,
            asDictionary: [ Tracks.CodingKeys.trackName.stringValue: newTracksName ]
        )
        print("트랙 이름 업데이트가 완료되었습니다. (updateTracksName 종료)")
    }

    /// 트랙과 해당 섹션들을 Firestore에서 삭제합니다.
    func removeTracksAndSection(tracksId: String) async throws {
        print("트랙 및 섹션 삭제를 시작합니다. 대상: \(tracksId) (removeTracksAndSection 시작)")
        try await FirestoreManager.shared.deleteAllDocumentsInSubcollection(
            under: .tracks, parentId: tracksId, subCollection: .section
        )
        try await FirestoreManager.shared.delete(collectionType: .tracks, documentID: tracksId)
        print("트랙 및 섹션 삭제가 완료되었습니다. (removeTracksAndSection 종료)")
    }
}

// MARK: - 곡 관리 (섹션)
extension HomeViewModel {
    /// 특정 트랙의 섹션 목록을 Firestore에서 비동기적으로 가져옵니다.
    /// - Returns: "일반" 섹션만 필터링한 섹션 배열
    func fetchSection(tracks: Tracks) async throws -> [Section] {
        print("특정 트랙의 섹션 목록을 가져옵니다. tracksId: \(tracks.tracksId) (fetchSection 시작)")
        do {
            let secs: [Section] = try await FirestoreManager.shared.fetchAllFromSubcollection(
                under: .tracks,
                parentId: tracks.tracksId.uuidString,
                subCollection: .section
            )
            print("섹션 목록 조회가 완료되었습니다. (fetchSection 종료)")
            return secs.filter { $0.sectionTitle == "일반" }
        } catch {
            print("섹션 목록 조회 중 오류가 발생했습니다. (fetchSection 실패): \(error.localizedDescription)")
            return []
        }
    }
}

// MARK: - 플로팅 버튼 / 화면 상태
extension HomeViewModel {
    /// 팀스페이스/프로젝트 확장 상태를 보고 어떤 FAB를 보여줄지 결정합니다.
    var fabMode: FABMode? {
        guard teamspace.state == .nonEmpty else { return nil }
        return (project.expandedID == nil) ? .addProject : .addTrack
    }

    /// 프로젝트가 하나도 없을 때는 라벨 버튼, 있을 때는 원형 버튼을 쓰기 위한 힌트
    var isProjectListEmpty: Bool { project.projects.isEmpty }
}

// MARK: - 프리뷰 데이터
extension HomeViewModel {
    /// 미리보기용 데이터가 채워진 HomeViewModel 인스턴스를 생성합니다.
    static func previewFilled() -> HomeViewModel {
        let viewModel = HomeViewModel()
        viewModel.teamspace.state = .nonEmpty
        viewModel.teamspace.list = [
            Teamspace(
                teamspaceId: UUID(),
                ownerId: "",
                teamspaceName: "이거뭐야"
            )
        ]
        viewModel.setCurrentTeamspace(viewModel.teamspace.list[0])

        viewModel.project.projects = [
            Project(projectId: UUID(), teamspaceId: viewModel.currentTeamspace!.teamspaceId.uuidString, creatorId: "preview-user", projectName: "뉴진스"),
            Project(projectId: UUID(), teamspaceId: viewModel.currentTeamspace!.teamspaceId.uuidString, creatorId: "preview-user", projectName: "르세라핌")
        ]
        viewModel.project.headerTitle = "프로젝트 목록"
        viewModel.project.expandedID = viewModel.project.projects[0].projectId
        viewModel.selectedProject = viewModel.project.projects[0]
        viewModel.tracks.byProject[viewModel.project.projects[0].projectId] = [
            Tracks(tracksId: UUID(), projectId: viewModel.project.projects[0].projectId.uuidString, creatorId: "preview-user", trackName: "Hype Boy (1절)")
        ]
        return viewModel
    }
}

// MARK: - 알림 허용 권한
extension HomeViewModel {
  
  /// 홈 진입 시 푸시 알림 권한 상태를 점검하고, 필요할 경우만 요청
  func setupNotificationAuthorizationIfNeeded() async {
    let center = UNUserNotificationCenter.current()
    let settings = await center.notificationSettings()
    
    switch settings.authorizationStatus {
      // 한 번도 요청하지 않은 경우에만 푸시 알림 권한 요청
    case .notDetermined:
      requestNotificationAuthorization()
    case .denied:
      print("User has denied notifications")
    case .authorized, .provisional, .ephemeral:
      print("Notifications already authorized.")
    @unknown default:
      print("Unknown notification authorization status.")
    }
  }
  
  /// 푸시 알림 권한을 사용자에게 물어봄 + 권한 승인하면 APNs에 등록
  func requestNotificationAuthorization() {
    let center = UNUserNotificationCenter.current()
    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
    center.requestAuthorization(options: authOptions) { granted, error in
      print("Notification permission state: \(granted)")
      if granted {
        Task { @MainActor in
          UIApplication.shared.registerForRemoteNotifications()
        }
      }
      if let error = error {
        print("Error requesting notifications: \(error)")
      }
    }
  }
}
