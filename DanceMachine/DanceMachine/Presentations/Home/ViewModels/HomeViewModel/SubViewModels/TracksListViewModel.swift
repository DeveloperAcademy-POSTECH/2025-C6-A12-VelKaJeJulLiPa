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

  var dataState         = TracksListDataState()
  var editingState      = TracksListEditingState()
  var alertState        = TracksListAlertState()
  var presentationState = TracksListPresentationState()

  private var cacheState = TracksListCacheState()

  private var projectKey: UUID? { project?.projectId }

  // SwiftData 캐시 스토어 (ProjectListVM에서 주입)
  @ObservationIgnored private var cacheStore: CacheStore?

  init(project: Project? = nil, cacheStore: CacheStore? = nil) {
    self.project = project
    self.cacheStore = cacheStore
  }

  // 나중에 주입할 수도 있게
  func injectCacheStore(_ cacheStore: CacheStore) {
    self.cacheStore = cacheStore
  }
}

extension TracksListViewModel {

  func onAppear() async {
    guard let project else {
      dataState.tracks = []
      dataState.isLoading = false
      dataState.errorText = "프로젝트 정보가 없습니다."
      return
    }

    let key = project.projectId
    let projectIdString = key.uuidString

    dataState.isLoading = true
    defer { dataState.isLoading = false }

    // 1) SwiftData 캐시 비교 로직
    if let cacheStore {
      let remoteUpdatedAtString = project.updatedAt?.iso8601KST()
      let cachedUpdatedAtString = try? cacheStore.checkedTracksUpdatedAt(projectId: projectIdString)

      print("""
      🧪 [TracksCache compare]
      - projectId: \(projectIdString)
      - remoteUpdatedAtString: \(remoteUpdatedAtString ?? "nil")
      - cachedUpdatedAtString: \(cachedUpdatedAtString ?? "nil")
      - isEqual: \(remoteUpdatedAtString == cachedUpdatedAtString)
      """)

      if let cachedUpdatedAtString,
         !cachedUpdatedAtString.isEmpty,
         cachedUpdatedAtString == remoteUpdatedAtString {

        let cachedTracks = (try? cacheStore.loadTracks(projectId: projectIdString)) ?? []
        dataState.tracks = cachedTracks
        dataState.errorText = nil
        dataState.isLoading = false

        // in-memory 캐시도 싱크
        cacheState.byProject[key] = cachedTracks
        cacheState.error[key] = nil

        print("🍀 tracks 캐시 히트. count=\(cachedTracks.count)")
        return
      } else {
        print("🥀 tracks 캐시 미스 → 서버 fetch")
      }
    }

    // 2) 캐시 미스 or cacheStore 없음 → 서버 로딩
    await fetchTracksFromServer(forceRefresh: true)
  }

  // 기존 loadTracks는 “서버 로딩 + 캐시 교체” 역할로 정리
  func loadTracks(forceRefresh: Bool = false) async {
    await fetchTracksFromServer(forceRefresh: forceRefresh)
  }

  private func fetchTracksFromServer(forceRefresh: Bool) async {
    guard let project else {
      dataState.tracks = []
      dataState.isLoading = false
      dataState.errorText = "프로젝트 정보가 없습니다."
      return
    }

    let key = project.projectId
    let projectIdString = key.uuidString

    // in-memory 캐시 히트 (empty여도 히트)
    if !forceRefresh,
       let cached = cacheState.byProject[key] {
      dataState.tracks = cached
      dataState.errorText = cacheState.error[key]
      dataState.isLoading = false
      print("🍀 in-memory tracks 캐시 히트. count=\(cached.count)")
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
        projectIdString,
        from: .tracks,
        where: Tracks.CodingKeys.projectId.stringValue
      )

      // result가 비어도 그대로 저장
      dataState.tracks = result
      cacheState.byProject[key] = result
      cacheState.error[key] = nil

      print("🍏 tracks 서버 fetch 완료. count=\(result.count)")

      // SwiftData 캐시 교체 (project.updatedAt이 nil이면 skip)
      if let cacheStore,
         let updatedAt = project.updatedAt {

        try? cacheStore.replaceTracks(
          projectId: projectIdString,
          projectIdUpdatedAt: updatedAt,
          tracks: result
        )

        print("🧊 tracks 캐시 교체 완료. updatedAt: \(updatedAt.iso8601KST())")
      }

    } catch {
      let message = error.localizedDescription
      dataState.errorText = message
      cacheState.error[key] = message

      // 실패했어도 "빈 캐시"를 남기고 싶으면 유지
      if cacheState.byProject[key] == nil {
        cacheState.byProject[key] = []
      }

      print("🙅🏻‍♂️ tracks fetch 실패: \(message)")
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

  // in-memory + SwiftData 캐시/상태 초기화
  @MainActor
  func clearCache() {
    guard let key = projectKey else { return }

    // in-memory 제거
    cacheState.byProject[key] = nil
    cacheState.error[key] = nil
    cacheState.loading.remove(key)

    dataState.tracks = []
    dataState.errorText = nil
    dataState.isLoading = false

    alertState.pendingDeleteTrack = nil
    alertState.isPresentingDeleteAlert = false

    // SwiftData 캐시 제거
    if let cacheStore {
      let pid = key.uuidString
      try? cacheStore.tracksCacheClear(projectId: pid)
      print("🧹 tracks SwiftData 캐시 클리어. projectId=\(pid)")
    }
  }
}

// MARK: - 삭제 플로우
extension TracksListViewModel {

  func requestDelete(track: Tracks) {
    alertState.pendingDeleteTrack = track
    alertState.isPresentingDeleteAlert = true
  }

  func confirmDelete() async {
    guard let project else { print("🙅🏻‍♂️곡 삭제 오류"); return }
    guard let pending = alertState.pendingDeleteTrack else { return }

    do {
      try await deleteTrack(trackId: pending.tracksId.uuidString)
      try await renewalProjectUpdateAt(projectId: project.projectId.uuidString)

      // 로컬 리스트에서 제거
      dataState.tracks.removeAll { $0.tracksId == pending.tracksId }

      // in-memory 캐시에서도 제거
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

      // SwiftData 캐시도 최신 tracks로 교체
      if let cacheStore,
         let updatedAt = project.updatedAt {
        let pid = project.projectId.uuidString
        try? cacheStore.replaceTracks(
          projectId: pid,
          projectIdUpdatedAt: updatedAt,
          tracks: dataState.tracks
        )
        print("🧊 delete 후 tracks 캐시 교체 완료")
      }

    } catch {
      dataState.errorText = error.localizedDescription
    }
  }
}

extension TracksListViewModel {

  func startEditing(track: Tracks) {
    editingState.rowState  = .editing
    editingState.editingId = track.tracksId
    editingState.editText  = track.trackName
  }

  func cancelEditing(keepText: Bool) {
    if !keepText { editingState.editText = "" }
    editingState.editingId = nil
    editingState.rowState  = .viewing
  }

  func commitIfPossible() async {
    guard editingState.rowState == .editing,
          let tid = editingState.editingId else { return }
    guard let project else { print("🙅🏻‍♂️곡 수정 오류"); return }

    let name = editingState.editText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !name.isEmpty else { return }

    do {
      try await updateTrackName(trackId: tid.uuidString, newName: name)
      try await renewalProjectUpdateAt(projectId: project.projectId.uuidString)

      if let idx = dataState.tracks.firstIndex(where: { $0.tracksId == tid }) {
        dataState.tracks[idx].trackName = name
      }

      presentationState.showUpdateTrackToast = true

      editingState.editText  = ""
      editingState.editingId = nil
      editingState.rowState  = .viewing

      // SwiftData 캐시도 최신 tracks로 교체
      if let cacheStore,
         let updatedAt = project.updatedAt {
        let pid = project.projectId.uuidString
        try? cacheStore.replaceTracks(
          projectId: pid,
          projectIdUpdatedAt: updatedAt,
          tracks: dataState.tracks
        )
        print("🧊 commit 후 tracks 캐시 교체 완료")
      }

    } catch {
      dataState.errorText = error.localizedDescription
    }
  }
}

// MARK: - 섹션 가져오기
extension TracksListViewModel {

  func fetchSection(tracks: Tracks) async throws -> [Section] {
    print("특정 트랙의 섹션 목록을 가져옵니다. tracksId: \(tracks.tracksId) (fetchSection 시작)")
    do {
      let secs: [Section] = try await FirestoreManager.shared.fetchAllFromSubcollection(
        under: .tracks,
        parentId: tracks.tracksId.uuidString,
        subCollection: .section
      )
      print("섹션 목록 조회가 완료되었습니다. (fetchSection 종료)")
      // 기존 "일반" 데이터와의 하위 호환성 유지
      return secs.filter { $0.sectionTitle == "General" || $0.sectionTitle == "일반" }
    } catch {
      print("섹션 목록 조회 중 오류가 발생했습니다. (fetchSection 실패): \(error.localizedDescription)")
      return []
    }
  }
}

// MARK: - Private Method
extension TracksListViewModel {

  private func renewalProjectUpdateAt(projectId: String) async throws {
    try await FirestoreManager.shared.updateTimestampField(
      field: .update,
      in: .project,
      documentId: projectId
    )
  }

  private func deleteTrack(trackId: String) async throws {
    try await FirestoreManager.shared.delete(
      collectionType: .tracks,
      documentID: trackId
    )
  }

  private func updateTrackName(trackId: String, newName: String) async throws {
    try await FirestoreManager.shared.updateFields(
      collection: .tracks,
      documentId: trackId,
      asDictionary: [Tracks.CodingKeys.trackName.stringValue: newName]
    )
  }
}

// MARK: - 새로고침 메서드
extension TracksListViewModel {

  // refreshable에서 쓸 "강제 서버 새로고침"
  func refreshFromServer() async {
    guard let project else {
      dataState.tracks = []
      dataState.isLoading = false
      dataState.errorText = "프로젝트 정보가 없습니다."
      return
    }

    let key = project.projectId
    let projectIdString = key.uuidString

    do {
      dataState.isLoading = true
      defer { dataState.isLoading = false }

      // 1) 무조건 서버 fetch
      let result: [Tracks] = try await FirestoreManager.shared.fetchAll(
        projectIdString,
        from: .tracks,
        where: Tracks.CodingKeys.projectId.stringValue
      )

      dataState.tracks = result
      dataState.errorText = nil

      // 2) in-memory 캐시 교체 (빈 배열도 저장)
      cacheState.byProject[key] = result
      cacheState.error[key] = nil

      print("🔄 refresh tracks 서버 fetch 완료. count=\(result.count)")

      // 3) SwiftData 캐시 교체 (updatedAt nil이면 Date()로 대체)
      if let cacheStore {
        let updatedAt = project.updatedAt ?? Date()
        try? cacheStore.replaceTracks(
          projectId: projectIdString,
          projectIdUpdatedAt: updatedAt,
          tracks: result
        )
        print("🧊 refresh 후 tracks 캐시 갱신 완료. updatedAt=\(updatedAt.iso8601KST())")
      }

    } catch {
      let msg = error.localizedDescription
      dataState.errorText = msg

      // 실패해도 "빈 캐시" 남기고 싶으면 유지
      if cacheState.byProject[key] == nil {
        cacheState.byProject[key] = []
      }

      print("🙅🏻‍♂️ refresh tracks 로딩 실패: \(msg)")
    }
  }
}
