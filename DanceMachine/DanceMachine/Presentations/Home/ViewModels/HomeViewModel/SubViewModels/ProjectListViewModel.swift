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
  
  /// 현재 선택된 팀스페이스 (FirebaseAuthManager의 currentTeamspace와 연동)
  var currentTeamspace: Teamspace? {
    FirebaseAuthManager.shared.currentTeamspace
  }
  
  // 부모(HomeView)에서 넣어줄 콜백들 (필요하면 사용)
  @ObservationIgnored var onCommitRename: ((UUID, String) async -> Void)?
  @ObservationIgnored var onTapProject: ((Project) -> Void)?

  // 프로젝트별 TracksListViewModel 캐시
  private var tracksVMByProject: [UUID: TracksListViewModel] = [:]
  
  // MARK: - 라이프사이클
  
  func onAppear() async {
    do {
      guard let currentTeamspace else {
        print("🙅🏻‍♂️현재 팀 스페이스 없음 error")
        return
      }
      dataState.isLoading = true
      defer { dataState.isLoading = false }
      
      dataState.projects = try await loadProject(
        teamspaceId: currentTeamspace.teamspaceId.uuidString
      )
      print("🍏 현재 팀 스페이스의 프로젝트를 불러옴. \(dataState.projects.count)개")
    } catch {
      print("프로젝트 목록 조회 중 오류가 발생했습니다. \(error.localizedDescription)")
    }
  }
  
  // MARK: - 헤더 primary 버튼 비활성화 로직
  
  func isPrimaryButtonDisabled() -> Bool {
    // 편집 모드가 아니면 의미 없음
    guard case .editing = editingState.rowState else { return false }
    
    let trimmed = editingState.editText
      .trimmingCharacters(in: .whitespacesAndNewlines)
    
    // 비어 있으면 비활성화
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
  
  /// 프로젝트 상태를 view -> editing 으로 전환
  func startEditing(project: Project) {
    editingState.rowState  = .editing
    editingState.editingId = project.projectId
    editingState.editText  = project.projectName
  }
  
  /// 프로젝트 상태를 editing -> view 로 전환
  func cancelEditing(keepText: Bool) {
    if !keepText {
      editingState.editText = ""
    }
    editingState.editingId = nil
    editingState.rowState  = .viewing
  }
  
  /// 헤더의 체크 버튼에서 호출할 저장 로직
  func commitIfPossible() async {
    do {
      guard case .editing = editingState.rowState,
            let pid = editingState.editingId else { return }
      
      guard let teamspaceId = currentTeamspace?.teamspaceId.uuidString else { print("🙅🏻‍♂️팀 스페이스 오류"); return }
      
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
      
      // 4) 편집 상태 초기화
      editingState.editText  = ""
      editingState.editingId = nil
      editingState.rowState  = .viewing
      
      self.presentationState.showNameUpdateCompletedToast = true // 성공 토스트 메세지
    } catch {
      self.presentationState.showNameUpdateFailToast = true // 실패 토스트 메세지
      print("🙅🏻‍♂️ 프로젝트 수정을 실패했습니다. error: \(error.localizedDescription)")
    }
  }
  
  // MARK: - 프로젝트별 per-row 상태
  
  func perRowState(for projectId: UUID) -> ProjectRowState {
    // 전체가 viewing 이면 무조건 보기 모드
    guard editingState.rowState == .editing else {
      return .viewing
    }
    
    // 편집 중인 아이디와 이 row의 아이디가 같을 때만 editing
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
  
  /// 삭제 Alert을 띄우는 메서드
  func requestDelete(project: Project) {
    presentationState.pendingDeleteProject     = project
    presentationState.isPresentingDeleteAlert  = true
  }
  
  /// 삭제 Alert 에서 확인 눌렀을 때
  func confirmDelete() async {
    do {
      guard let teamspaceId = currentTeamspace?.teamspaceId.uuidString else { print("🙅🏻‍♂️팀 스페이스 오류"); return }
      guard let project = presentationState.pendingDeleteProject else { return }
      
      try await deleteProject(projectId: project.projectId.uuidString)
      try await renewalTeamspaceUpdateAt(teamspaceId: teamspaceId)
      
      // TODO: batch 추가하기(곡, 비디오, 영상 삭제 연쇄삭제)
      // 새로 고침
      await onAppear()
      
      presentationState.isPresentingDeleteAlert = false
      presentationState.pendingDeleteProject    = nil
    } catch {
      print("🙅🏻‍♂️프로젝트 삭제에 실패했습니다. error: \(error.localizedDescription)")
    }
  }
}

// MARK: - Private Method
extension ProjectListViewModel {
  /// 현재 팀 스페이스의 프로젝트를 로드
  private func loadProject(teamspaceId: String) async throws -> [Project] {
    try await FirestoreManager.shared.fetchAll(
      teamspaceId,
      from: .project,
      where: Project.CodingKeys.teamspaceId.stringValue
    )
  }
  
  /// 프로젝트 삭제
  private func deleteProject(projectId: String) async throws {
    try await FirestoreManager.shared.delete(
      collectionType: .project,
      documentID: projectId
    )
  }
  
  /// 프로젝트 이름 수정
  private func updateProjectName(projectId: String, newName: String) async throws {
    try await FirestoreManager.shared.updateFields(
      collection: .project,
      documentId: projectId,
      asDictionary: [Project.CodingKeys.projectName.stringValue: newName]
    )
  }
  
  /// 현재 프로젝트를 포함하는 팀 스페이스의 updateAt을 갱신하는 메서드입니다.
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
     let newVM = TracksListViewModel(project: project)
     tracksVMByProject[project.projectId] = newVM
     return newVM
   }

   // 특정 프로젝트 캐시 제거 (삭제/나가기 등에서 호출)
   @MainActor
   func removeTracksCache(for projectId: UUID) {
     tracksVMByProject[projectId] = nil
   }

   // 전체 트랙 캐시 제거가 필요하면
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
