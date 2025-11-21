//
//  TracksListViewModel.swift
//  DanceMachine
//
//  Created by 김진혁 on 11/18/25.
//

import Foundation

struct TracksListDataState {
  var tracks: [Tracks] = []
  var isLoading: Bool = false
  var errorText: String? = nil
}

struct TracksListEditingState {
  var rowState: TracksRowState = .viewing
  var editingId: UUID?
  var editText: String = ""
}

struct TracksListAlertState {
  var isPresentingDeleteAlert: Bool = false
  var presentingCreateTrackSheet: Bool = false
  var pendingDeleteTrack: Tracks? = nil
}

struct TracksListPresentationState {
  var showDeleteCompletedToast: Bool = false
  var showUpdateTrackToast: Bool = false
}

struct TracksListCacheState {
  var byProject: [UUID: [Tracks]] = [:]
  var loading: Set<UUID> = []
  var error: [UUID: String] = [:]
}

@Observable
final class TracksListViewModel {
  
  let project: Project?
  
  var dataState        = TracksListDataState()
  var editingState     = TracksListEditingState()
  var alertState       = TracksListAlertState()
  var presentationState = TracksListPresentationState()
  
  private var cacheState = TracksListCacheState()
  
  private var projectKey: UUID? { project?.projectId }
  
  init(project: Project? = nil) {
    self.project = project
  }
}

extension TracksListViewModel {
  
  func onAppear() async {
    guard let key = projectKey else {
      dataState.tracks = []
      dataState.isLoading = false
      dataState.errorText = "프로젝트 정보가 없습니다."
      return
    }
    
    if let cached = cacheState.byProject[key] {
      dataState.tracks    = cached
      dataState.errorText = cacheState.error[key]
      dataState.isLoading = false
    }
    
    await loadTracks()
  }
  
  func loadTracks(forceRefresh: Bool = false) async {
    guard let project else {
      dataState.tracks = []
      dataState.isLoading = false
      dataState.errorText = "프로젝트 정보가 없습니다."
      return
    }
    
    let key = project.projectId
    
    if !forceRefresh,
       let cached = cacheState.byProject[key],
       !cached.isEmpty {
      dataState.tracks    = cached
      dataState.errorText = cacheState.error[key]
      dataState.isLoading = false
      return
    }
    
    do {
      dataState.isLoading = true
      dataState.errorText = nil
      cacheState.loading.insert(key)
      cacheState.error[key] = nil
      
      defer {
        dataState.isLoading = false
        cacheState.loading.remove(key)
      }
      
      let result: [Tracks] = try await FirestoreManager.shared.fetchAll(
        project.projectId.uuidString,
        from: .tracks,
        where: Tracks.CodingKeys.projectId.stringValue
      )
      
      dataState.tracks = result
      cacheState.byProject[key] = result
      cacheState.error[key]     = nil
      
    } catch {
      let message = error.localizedDescription
      dataState.errorText = message
      cacheState.error[key] = message
    }
  }
  
  func perRowState(for id: UUID) -> TracksRowState {
    if editingState.rowState == .editing,
       editingState.editingId == id {
      return .editing
    } else {
      return .viewing
    }
  }
}

// MARK: - 삭제 플로우 (프로젝트와 동일)
extension TracksListViewModel {
  
  // 1) 삭제 요청: pending 세팅 + alert 띄우기
  func requestDelete(track: Tracks) {
    alertState.pendingDeleteTrack = track
    alertState.isPresentingDeleteAlert = true
  }
  
  // 2) 삭제 확정: 서버 삭제 + 로컬/캐시 갱신 + 토스트 트리거
  func confirmDelete() async {
    guard let project else { return }
    guard let pending = alertState.pendingDeleteTrack else { return }
    
    do {
      try await deleteTrack(trackId: pending.tracksId.uuidString)
      
      // 로컬 리스트에서 제거
      dataState.tracks.removeAll { $0.tracksId == pending.tracksId }
      
      // 캐시에서도 제거
      let key = project.projectId
      if var cached = cacheState.byProject[key] {
        cached.removeAll { $0.tracksId == pending.tracksId }
        cacheState.byProject[key] = cached
      }
      
      // alert 상태 정리
      alertState.pendingDeleteTrack = nil
      alertState.isPresentingDeleteAlert = false
      
      // 완료 토스트
      presentationState.showDeleteCompletedToast = true
      
    } catch {
      dataState.errorText = error.localizedDescription
    }
  }
  
  private func deleteTrack(trackId: String) async throws {
    // FirestoreManager에 맞는 실제 삭제 API로 교체해서 쓰면 됨
    try await FirestoreManager.shared.delete(
      collectionType: .tracks,
      documentID: trackId
    )
  }
}

extension TracksListViewModel {
  
  // 트랙 수정 시작
  func startEditing(track: Tracks) {
    editingState.rowState  = .editing
    editingState.editingId = track.tracksId
    editingState.editText  = track.trackName
  }
  
  // 트랙 수정 취소
  func cancelEditing(keepText: Bool) {
    if !keepText { editingState.editText = "" }
    editingState.editingId = nil
    editingState.rowState  = .viewing
  }
  
  // 수정 완료
  func commitIfPossible() async {
    guard editingState.rowState == .editing,
          let tid = editingState.editingId else { return }
    
    let name = editingState.editText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !name.isEmpty else { return }
    
    do {
      try await updateTrackName(trackId: tid.uuidString, newName: name)
      
      if let idx = dataState.tracks.firstIndex(where: { $0.tracksId == tid }) {
        dataState.tracks[idx].trackName = name
      }
      
      self.presentationState.showUpdateTrackToast = true
      
      editingState.editText  = ""
      editingState.editingId = nil
      editingState.rowState  = .viewing
      
    } catch {
      dataState.errorText = error.localizedDescription
    }
  }
  
  private func updateTrackName(trackId: String, newName: String) async throws {
    try await FirestoreManager.shared.updateFields(
      collection: .tracks,
      documentId: trackId,
      asDictionary: [Tracks.CodingKeys.trackName.stringValue: newName]
    )
  }
}

// MARK: - 섹션 가져오기
extension TracksListViewModel {
  
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
