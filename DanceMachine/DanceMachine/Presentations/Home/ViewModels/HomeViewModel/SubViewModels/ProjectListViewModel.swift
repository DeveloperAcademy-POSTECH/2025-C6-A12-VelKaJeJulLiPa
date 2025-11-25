//
//  ProjectListViewModel.swift
//  DanceMachine
//
//  Created by 김진혁 on 11/17/25.
//

import Foundation

struct ProjectListDataState {
  // 1. 실제 데이터 & 로딩
  var projects: [Project] = []
  var isLoading: Bool = false
}

struct ProjectListEditingState {
  // 2. 편집/헤더/확장 관련
  var rowState: ProjectRowState = .viewing        // 전체 헤더 상태 (보기 / 편집)
  var headerTitle: String = "프로젝트 목록"         // 헤더 타이틀
  var editingId: UUID?                            // 현재 수정 중인 프로젝트 id
  var editText: String = ""                       // 수정 중인 이름
  var expandedId: UUID?                           // 펼쳐진 프로젝트 id
}

struct ProjectListAlertState {
  // 3. 토스트 / 알럿 등 피드백 UI
  var showNameLengthToast: Bool = false
  var showNameLengthTrackToast: Bool = false
  var showCompletedToast: Bool = false
  var showNameUpdateCompletedToast: Bool = false // 프로젝트 이름 수정 완료 토스트 메세지
  var showNameUpdateFailToast: Bool = false // 프로젝트 이름 수정 실패 토스트 메세지
  var isPresentingDeleteAlert: Bool = false
  var pendingDeleteProject: Project?
  var presentingCreateProjectSheet: Bool = false // 새 프로젝트 만들기 시트
}

@Observable
final class ProjectListViewModel {
  
  var dataState          = ProjectListDataState()
  var editingState       = ProjectListEditingState()
  var presentationState  = ProjectListAlertState()
  
  // 현재 선택된 팀스페이스 (FirebaseAuthManager의 currentTeamspace와 연동)
  var currentTeamspace: Teamspace? {
    FirebaseAuthManager.shared.currentTeamspace
  }
  
  // 부모(HomeView)에서 넣어줄 콜백들 (필요하면 사용)
  @ObservationIgnored var onCommitRename: ((UUID, String) async -> Void)?
  @ObservationIgnored var onTapProject: ((Project) -> Void)?
  
  // 프로젝트별 TracksListViewModel 캐시
  private var tracksVMByProject: [UUID: TracksListViewModel] = [:]
  
  // Project 캐시 스토어 (뷰에서 1번 주입해두면 내부에서 계속 사용)
  @ObservationIgnored private var cacheStore: CacheStore?
  
  // MARK: - 라이프사이클
  
  // 뷰에서 cacheStore를 넘겨줄 때 사용하는 entry
  func onAppear(cacheStore: CacheStore) async {
    self.cacheStore = cacheStore
    await onAppear()
  }
  
  // 기존 entry. cacheStore가 주입돼 있으면 캐싱 로직을 사용하고,
  // 없으면 서버 로딩만 수행
  func onAppear() async {
    do {
      guard let currentTeamspace else {
        print("🙅🏻‍♂️현재 팀 스페이스 없음 error")
        return
      }

      dataState.isLoading = true
      defer { dataState.isLoading = false }

      let teamspaceId = currentTeamspace.teamspaceId.uuidString

      if let cacheStore {
        let remoteUpdatedAtString = currentTeamspace.updatedAt?.iso8601KST()
        let cachedUpdatedAtString = try cacheStore.checkedProjectUpdatedAt(teamspaceId: teamspaceId)

        debugCacheLog(
          phase: "compare",
          teamspaceId: teamspaceId,
          remoteUpdatedAtString: remoteUpdatedAtString,
          cachedUpdatedAtString: cachedUpdatedAtString
        )

        if !cachedUpdatedAtString.isEmpty,
           cachedUpdatedAtString == remoteUpdatedAtString {

          let cachedProjects = try cacheStore.loadProjects(teamspaceId: teamspaceId)
          dataState.projects = cachedProjects

          print("🍀 캐시 히트 → cache projects 사용. count=\(cachedProjects.count)")
          cacheStore.debugPrintProjectCache(teamspaceId: teamspaceId, prefix: "🍀")
          return
        } else {
          print("🥀 캐시 미스 → 서버 fetch 진행")
          cacheStore.debugPrintProjectCache(teamspaceId: teamspaceId, prefix: "🥀(before fetch)")
        }
      }

      // 서버 로딩
      let freshProjects = try await loadProject(teamspaceId: teamspaceId)
      dataState.projects = freshProjects
      print("🍏 서버 fetch 완료. count=\(freshProjects.count)")

      if let cacheStore,
         let updatedAt = currentTeamspace.updatedAt {

        try cacheStore.replaceProjects(
          teamspaceId: teamspaceId,
          teamspaceUpdatedAt: updatedAt,
          project: freshProjects
        )

        print("🧊 캐시 교체 완료")
        cacheStore.debugPrintProjectCache(teamspaceId: teamspaceId, prefix: "🧊(after replace)")
      }

    } catch {
      print("프로젝트 목록 조회 중 오류: \(error.localizedDescription)")
    }
  }
  
  // MARK: - (옵션) 프로젝트 캐시 비우기
  
  // refreshable에서 호출할 용도
  func clearProjectCache() {
    guard let cacheStore,
          let teamspaceId = currentTeamspace?.teamspaceId.uuidString
    else { return }
    try? cacheStore.projectCacheClear(teamspaceId: teamspaceId)
  }
  
  // MARK: - 헤더 primary 버튼 비활성화 로직
  
  func isPrimaryButtonDisabled() -> Bool {
    guard case .editing = editingState.rowState else { return false }
    
    let trimmed = editingState.editText
      .trimmingCharacters(in: .whitespacesAndNewlines)
    
    return trimmed.isEmpty
  }
  
  // MARK: - 확장 / 헤더 타이틀
  
  func toggleExpand(_ project: Project) {
    if editingState.expandedId == project.projectId {
      editingState.expandedId = nil
      editingState.headerTitle = "프로젝트 목록"
    } else {
      editingState.expandedId = project.projectId
      editingState.headerTitle = project.projectName
    }
  }
  
  // MARK: - 편집 상태 전환
  
  func startEditing(project: Project) {
    editingState.rowState  = .editing
    editingState.editingId = project.projectId
    editingState.editText  = project.projectName
  }
  
  func cancelEditing(keepText: Bool) {
    if !keepText {
      editingState.editText = ""
    }
    editingState.editingId = nil
    editingState.rowState  = .viewing
  }
  
  func commitIfPossible() async {
    do {
      guard case .editing = editingState.rowState,
            let pid = editingState.editingId else { return }
      
      guard let teamspaceId = currentTeamspace?.teamspaceId.uuidString else {
        print("🙅🏻‍♂️팀 스페이스 오류")
        return
      }
      
      let name = editingState.editText
        .trimmingCharacters(in: .whitespacesAndNewlines)
      
      guard !name.isEmpty else { return }
      
      // 1) Firestore 업데이트
      try await updateProjectName(projectId: pid.uuidString, newName: name)
      
      // 2) updateAt 갱신
      try await renewalTeamspaceUpdateAt(teamspaceId: teamspaceId)
      
      // 3) 로컬 배열 반영
      if let index = dataState.projects.firstIndex(where: { $0.projectId == pid }) {
        dataState.projects[index].projectName = name
      } else {
        print("⚠️ commitIfPossible: 해당 projectId를 로컬 projects에서 찾지 못했습니다.")
      }
      
      // 4) 필요하면 상위 콜백 호출
      if let onCommitRename {
        await onCommitRename(pid, name)
      }
      
      // 5) 편집 상태 초기화
      editingState.editText  = ""
      editingState.editingId = nil
      editingState.rowState  = .viewing
      
      presentationState.showNameUpdateCompletedToast = true
      
      // 6) 캐시 업데이트도 최신으로 교체
      if let cacheStore,
         let currentTeamspace,
         let updatedAt = currentTeamspace.updatedAt {
        
        let tid = currentTeamspace.teamspaceId.uuidString
        try? cacheStore.replaceProjects(
          teamspaceId: tid,
          teamspaceUpdatedAt: updatedAt,
          project: dataState.projects
        )
        
        print("🧪 commit 후 캐시 교체됨")
        cacheStore.debugPrintProjectCache(teamspaceId: tid, prefix: "🧪(after commit)")
      }
      
    } catch {
      presentationState.showNameUpdateFailToast = true
      print("🙅🏻‍♂️ 프로젝트 수정을 실패했습니다. error: \(error.localizedDescription)")
    }
  }
  
  // MARK: - 프로젝트별 per-row 상태
  
  func perRowState(for projectId: UUID) -> ProjectRowState {
    guard editingState.rowState == .editing else {
      return .viewing
    }
    
    if editingState.editingId == projectId {
      return .editing
    } else {
      return .viewing
    }
  }
  
  // MARK: - 기타 액션
  
  func tapRow(_ project: Project) {
    onTapProject?(project)
  }
  
  func requestDelete(project: Project) {
    presentationState.pendingDeleteProject     = project
    presentationState.isPresentingDeleteAlert  = true
  }
  
  func confirmDelete() async {
    guard let teamspaceId = currentTeamspace?.teamspaceId.uuidString else {
      print("🙅🏻‍♂️팀 스페이스 오류")
      return
    }
    guard let project = presentationState.pendingDeleteProject else { return }

    
    let removingId = project.projectId
    let backupProjects = dataState.projects

    if let idx = dataState.projects.firstIndex(where: { $0.projectId == removingId }) {
      dataState.projects.remove(at: idx)
    }

   
    if editingState.expandedId == removingId {
      editingState.expandedId = nil
      editingState.headerTitle = "프로젝트 목록"
    }

 
    presentationState.isPresentingDeleteAlert = false
    presentationState.pendingDeleteProject = nil

    do {
      try await deleteProject(projectId: removingId.uuidString)
      try await renewalTeamspaceUpdateAt(teamspaceId: teamspaceId)


      bumpLocalTeamspaceUpdatedAt()

      if let cacheStore,
         let currentTeamspace,
         let updatedAt = currentTeamspace.updatedAt {

        let tid = currentTeamspace.teamspaceId.uuidString
        try? cacheStore.replaceProjects(
          teamspaceId: tid,
          teamspaceUpdatedAt: updatedAt,
          project: dataState.projects
        )
        print("🧪 delete 후 캐시 교체됨")
        cacheStore.debugPrintProjectCache(teamspaceId: tid, prefix: "🧪(after delete)")
      }
    } catch {
      // 6) 실패하면 롤백 ✅ NEW
      dataState.projects = backupProjects
      presentationState.showNameUpdateFailToast = true
      print("🙅🏻‍♂️프로젝트 삭제 실패. rollback 수행:", error.localizedDescription)
    }
  }

  // currentTeamspace.updatedAt을 로컬에서도 맞춰주는 유틸 ✅ NEW
  private func bumpLocalTeamspaceUpdatedAt() {
    // 서버 timestamp와 1:1로 맞출 순 없지만,
    // 캐시 비교용으로 “로컬도 최신이라고” 동기화해주는 목적
    if var ts = FirebaseAuthManager.shared.currentTeamspace {
      ts.updatedAt = Date()
      FirebaseAuthManager.shared.currentTeamspace = ts
    }
  }
}

// MARK: - Private Method
extension ProjectListViewModel {
  private func loadProject(teamspaceId: String) async throws -> [Project] {
    try await FirestoreManager.shared.fetchAll(
      teamspaceId,
      from: .project,
      where: Project.CodingKeys.teamspaceId.stringValue
    )
  }
  
  private func deleteProject(projectId: String) async throws {
    try await FirestoreManager.shared.delete(
      collectionType: .project,
      documentID: projectId
    )
  }
  
  private func updateProjectName(projectId: String, newName: String) async throws {
    try await FirestoreManager.shared.updateFields(
      collection: .project,
      documentId: projectId,
      asDictionary: [Project.CodingKeys.projectName.stringValue: newName]
    )
  }
  
  private func renewalTeamspaceUpdateAt(teamspaceId: String) async throws {
    try await FirestoreManager.shared.updateTimestampField(
      field: .update,
      in: .teamspace,
      documentId: teamspaceId
    )
  }
}

// MARK: - 곡(Tracks) 내부 캐싱 관련 메서드
extension ProjectListViewModel {
  // 프로젝트에 대한 tracksVM 가져오기 (없으면 생성해서 저장)
  @MainActor
  func tracksViewModel(for project: Project) -> TracksListViewModel {
    if let cached = tracksVMByProject[project.projectId] {
      return cached
    }
    let newVM = TracksListViewModel(project: project, cacheStore: cacheStore)
    tracksVMByProject[project.projectId] = newVM
    return newVM
  }

  // 특정 프로젝트 캐시 제거 (삭제/나가기 등에서 호출)
  @MainActor
  func removeTracksCache(for projectId: UUID) {
    tracksVMByProject[projectId] = nil
  }

  // 전체 트랙 캐시 제거
  @MainActor
  func clearAllTracksCache() {
    tracksVMByProject.removeAll()
  }
}





//@Observable
//final class ProjectListViewModel {
//
//  var state = ProjectListState()
//
//  private(set) var currentTeamspace: Teamspace? = FirebaseAuthManager.shared.currentTeamspace
//
//  // TODO: 현재 프로젝트를 불러오는 매서드
//  /// 현재 팀스페이스의 프로젝트 목록을 Firestore에서 비동기적으로 가져옵니다.
//  func fetchCurrentTeamspaceProject() async {
//    do {
//      guard let currentTeamspace = currentTeamspace else { print("🔥현재 팀 스페이스 없음 error"); return }
//      self.state.projects = try await loadProject(teamspaceId: currentTeamspace.teamspaceId.uuidString)
//      print("🍏 현재 팀 스페이스의 프로젝트를 불러옴. \(self.state.projects.count)개")
//    } catch {
//      print("프로젝트 목록 조회 중 오류가 발생했습니다. \(error.localizedDescription)")
//    }
//  }
//
//
//}

// MARK: - private Method
//extension ProjectListViewModel {
//
//  private func loadProject(teamspaceId: String) async throws -> [Project] {
//    return try await FirestoreManager.shared.fetchAll(
//      teamspaceId,
//      from: .project,
//      where: Project.CodingKeys.teamspaceId.stringValue
//    )
//  }
//
//}


// MARK: - Debug logger
extension ProjectListViewModel {

  private func debugCacheLog(
    phase: String,
    teamspaceId: String,
    remoteUpdatedAtString: String?,
    cachedUpdatedAtString: String?
  ) {
    print("""
    🧪 [ProjectCache \(phase)]
    - teamspaceId: \(teamspaceId)
    - remoteUpdatedAtString: \(remoteUpdatedAtString ?? "nil")
    - cachedUpdatedAtString: \(cachedUpdatedAtString ?? "nil")
    - isEqual: \(remoteUpdatedAtString == cachedUpdatedAtString)
    - localProjectsCount(now): \(dataState.projects.count)
    """)
  }
}


// MARK: - 새로고침 메서드
extension ProjectListViewModel {

  // refreshable에서 쓸 "강제 서버 새로고침"
  func refreshFromServer() async {
    do {
      guard let currentTeamspace else {
        print("🙅🏻‍♂️현재 팀 스페이스 없음 error")
        return
      }

      dataState.isLoading = true
      defer { dataState.isLoading = false }

      let teamspaceId = currentTeamspace.teamspaceId.uuidString

      // 1) 무조건 서버에서 fetch
      let freshProjects = try await loadProject(teamspaceId: teamspaceId)
      dataState.projects = freshProjects
      print("🔄 refresh 서버 fetch 완료. count=\(freshProjects.count)")

      // 2) fetch 결과로 캐시 교체 (updatedAt nil이면 Date()로 대체)
      if let cacheStore {
        let updatedAt = currentTeamspace.updatedAt ?? Date()
        try? cacheStore.replaceProjects(
          teamspaceId: teamspaceId,
          teamspaceUpdatedAt: updatedAt,
          project: freshProjects
        )
        print("🧊 refresh 후 프로젝트 캐시 갱신 완료. updatedAt=\(updatedAt.iso8601KST())")
        cacheStore.debugPrintProjectCache(teamspaceId: teamspaceId, prefix: "🧊(after refresh)")
      }

    } catch {
      print("🙅🏻‍♂️ refresh 프로젝트 로딩 실패: \(error.localizedDescription)")
    }
  }
}
