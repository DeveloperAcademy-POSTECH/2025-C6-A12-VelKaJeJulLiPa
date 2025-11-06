//
//  VideoListVM.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/12/25.
//

import Foundation

@Observable
final class VideoListViewModel {
  private let store = FirestoreManager.shared
  private let storage = FireStorageManager.shared
  private let dataCacheManager = VideoDataCacheManager.shared
  
  var videos: [Video] = []
  var section: [Section] = []
  var track: [Track] = []
  
  var isLoading: Bool = false
  var errorMsg: String? = nil
  
  var selectedSection: Section?
  
}
// MARK: - UI 관련
extension VideoListViewModel {
  // 섹션 필터링
  var filteredVideos: [Video] {
    guard let selectedSection = selectedSection else {
      return videos
    }
    let sectionTracks = track.filter {
      $0.sectionId == selectedSection.sectionId
    }
    let videoIds = Set(sectionTracks.map { $0.videoId })
    
    return videos.filter { videoIds.contains($0.videoId.uuidString) }
  }
}
// MARK: - 로컬 상태 업데이트 (캐시와 동기화)
extension VideoListViewModel {
  /// 섹션 추가
  @MainActor
  func addSection(_ section: Section) {
    if !self.section.contains(where: { $0.sectionId == section.sectionId }) {
      self.section.append(section)
      print("VideoListViewModel: 섹션 추가됨 - \(section.sectionTitle)")
    }
  }

  /// 섹션 삭제
  @MainActor
  func removeSection(sectionId: String) {
    self.section.removeAll { $0.sectionId == sectionId }
    self.track.removeAll { $0.sectionId == sectionId }

    // 삭제된 섹션이 선택되어 있었다면 첫 번째 섹션으로 변경
    if selectedSection?.sectionId == sectionId {
      selectedSection = section.first
    }
    print("VideoListViewModel: 섹션 삭제됨 - \(sectionId)")
  }

  /// 섹션 제목 수정
  @MainActor
  func updateSectionTitle(sectionId: String, newTitle: String) {
    if let index = self.section.firstIndex(where: { $0.sectionId == sectionId }) {
      var updatedSection = self.section[index]
      updatedSection.sectionTitle = newTitle
      self.section[index] = updatedSection

      // 선택된 섹션도 업데이트
      if selectedSection?.sectionId == sectionId {
        selectedSection = updatedSection
      }
      print("VideoListViewModel: 섹션 제목 수정됨 - \(newTitle)")
    }
  }

  /// 트랙(영상) 섹션 이동
  @MainActor
  func moveTrack(trackId: String, toSectionId: String) {
    if let index = self.track.firstIndex(where: { $0.trackId == trackId }) {
      var updatedTrack = self.track[index]
      updatedTrack.sectionId = toSectionId
      self.track[index] = updatedTrack
      print("VideoListViewModel: 트랙 이동됨 - \(trackId) → \(toSectionId)")
    }
  }

  /// 섹션 삭제 시 하위 비디오/트랙 모두 삭제
  @MainActor
  func removeSectionWithVideos(sectionId: String) {
    // 해당 섹션의 트랙들 찾기
    let tracksToDelete = self.track.filter { $0.sectionId == sectionId }
    let videoIdsToDelete = Set(tracksToDelete.map { $0.videoId })

    // 트랙 삭제
    self.track.removeAll { $0.sectionId == sectionId }

    // 비디오 삭제 (해당 비디오가 다른 섹션에 없는 경우만)
    for videoId in videoIdsToDelete {
      let stillExists = self.track.contains { $0.videoId == videoId }
      if !stillExists {
        self.videos.removeAll { $0.videoId.uuidString == videoId }
      }
    }

    // 섹션 삭제
    self.section.removeAll { $0.sectionId == sectionId }

    // 삭제된 섹션이 선택되어 있었다면 첫 번째 섹션으로 변경
    if selectedSection?.sectionId == sectionId {
      selectedSection = section.first
    }
    print("VideoListViewModel: 섹션 및 하위 데이터 삭제됨 - \(sectionId)")
  }
}
// MARK: - 서버 메서드
extension VideoListViewModel {
  // 모든 데이터 불러오기
  func loadFromServer(tracksId: String) async {
    if ProcessInfo.isRunningInPreviews { return } // 프리뷰 전용
    
    let startTime = Date()
    
    await MainActor.run {
      self.isLoading = true
      self.errorMsg = nil
    }
    
    // 1. 캐시 확인 우선
    if let cachedData = await dataCacheManager.getCachedData(for: tracksId) {
      print("캐시에서 데이터 로드")
      
      // 최소 로딩 시간 보장 (스켈레톤 뷰 1.5초)
      await TaskTimeUtility.waitForMinimumLoadingTime(
        startTime: startTime
      )
      
      await MainActor.run {
        self.section = cachedData.section
        self.track = cachedData.track
        self.videos = cachedData.videos
        
        if let firstSection = cachedData.section.first {
          self.selectedSection = firstSection
        }
        self.isLoading = false
      }
      return
    }
    
    // 2. 캐시 없으면 그때 서버에서 로드
    do {
      print("서버에서 로드 시작")
      // 1. Tracks -> Section 목록 가져오기
      let fetchSection = try await self.fetchSection(in: tracksId)
      print("불러온 section 개수\(fetchSection.count)")
      var allTrack: [Track] = []
      var videoIds: Set<String> = []
      // 2. 각 Section에서 Track 목록 가져오기
      for section in fetchSection {
        let track = try await self.fetchTrack(
          in: tracksId,
          withIn: section.sectionId
        )
        allTrack.append(contentsOf: track)
        print("불러온 track 개수\(allTrack.count)")
        // 3. Track의 videoId 수집
        for t in track {
          print("\(t.videoId)")
          videoIds.insert(t.videoId)
        }
      }
      print("불러온 videoId 개수\(videoIds.count)")
      
      // 4. 수집한 videoId로 Video 문서들 가져오기 (동시 + 결측 허용)
      _ = videoIds.filter { UUID(uuidString: $0) != nil }
      var fetchedVideos: [Video] = []
      // 4. 수집한 videoId로 Video 문서들 가져오기
      for videoId in videoIds {
        // 하나라도 문서 오류로 실패하면 함수 자체 catch로 빠져 아무것도 로드 안되는 이슈로 for문을 do catch 구문으로 감싸서 해결
        do {
          let video: Video = try await store.get(videoId, from: .video)
          print("수집한 개별 videoID: \(videoId)")
          fetchedVideos.append(video)
        } catch {
          print("비디오 문서 없음 스킵 : \(error)")
          print("에러: \(error)")
          continue
        }
      }
      fetchedVideos.sort {
        ($0.createdAt ?? .distantPast > ($1.createdAt ?? .distantPast))
      }
      
      // 3. 로드 후 캐시에 저장
      try await dataCacheManager.cache(
        video: fetchedVideos,
        track: allTrack,
        section: fetchSection,
        for: tracksId
      )
      
      // 최소 로딩 시간 보장 (스켈레톤 뷰 0.8초)
      await TaskTimeUtility.waitForMinimumLoadingTime(
        startTime: startTime
      )
      
      // 4. UI 업데이트
      await MainActor.run {
        let previousSelectedId = self.selectedSection?.sectionId
        self.section = fetchSection
        self.track = allTrack
        self.videos = fetchedVideos
        
        if let prevId = previousSelectedId,
           let stillExists = fetchSection.first(where: { $0.sectionId == prevId }) {
          self.selectedSection = stillExists
        } else {
          self.selectedSection = fetchSection.first
        }
        
        self.isLoading = false
      }
    } catch {
      // 최소 로딩 시간 보장 (스켈레톤 뷰 1.5초)
      await TaskTimeUtility.waitForMinimumLoadingTime(
        startTime: startTime
      )
      
      await MainActor.run {
        self.isLoading = false
        // 동작 중 일부 videoId가 누락되어도 전체를 중단하지 않도록,
        // 이미 로딩된 비디오가 없다면에만 에러 메시지를 표시
        if self.videos.isEmpty {
          self.errorMsg = VideoError.fetchFailed.userMsg
        }
        print("비디오 에러: \(VideoError.fetchFailed.debugMsg)")
        print("상세 에러: \(error)")
      }
    }
  }
  // MARK: 새 영상 캐시에 추가
  func addNewVideo(video: Video, track: Track, traksId: String) async {
    await dataCacheManager.addVideo(
      video,
      track: track,
      to: traksId
    )
    await MainActor.run {
      if !self.videos.contains(where: { $0.videoId == video.videoId }) {
        self.videos.insert(video, at: 0)
      }
      if !self.track.contains(where: { $0.trackId == track.trackId }) {
        self.track.append(track)
      }
      print("새 영상 캐시에 추가: \(video.videoTitle)")
    }
  }

  // MARK: 강제 서버 새로고침 (Pull-to-refresh용)
  func forceRefreshFromServer(tracksId: String) async {
    if ProcessInfo.isRunningInPreviews { return }

    let startTime = Date()

    await MainActor.run {
      self.isLoading = true
      self.errorMsg = nil
    }

    // 캐시 무시하고 무조건 서버에서 로드
    do {
      print("강제 서버 새로고침 시작")

      let fetchSection = try await self.fetchSection(in: tracksId)
      var allTrack: [Track] = []
      var videoIds: Set<String> = []

      for section in fetchSection {
        let track = try await self.fetchTrack(
          in: tracksId,
          withIn: section.sectionId
        )
        allTrack.append(contentsOf: track)

        for t in track {
          videoIds.insert(t.videoId)
        }
      }

      var fetchedVideos: [Video] = []
      for videoId in videoIds {
        do {
          let video: Video = try await store.get(videoId, from: .video)
          fetchedVideos.append(video)
        } catch {
          print("비디오 문서 없음 스킵 : \(error)")
          continue
        }
      }

      fetchedVideos.sort {
        ($0.createdAt ?? .distantPast > ($1.createdAt ?? .distantPast))
      }

      // 새로 받은 데이터로 캐시 업데이트
      try await dataCacheManager.cache(
        video: fetchedVideos,
        track: allTrack,
        section: fetchSection,
        for: tracksId
      )

      // 최소 로딩 시간 보장 (1.5초)
      await TaskTimeUtility.waitForMinimumLoadingTime(
        startTime: startTime
      )

      await MainActor.run {
        let previousSelectedId = self.selectedSection?.sectionId
        self.section = fetchSection
        self.track = allTrack
        self.videos = fetchedVideos

        if let prevId = previousSelectedId,
           let stillExists = fetchSection.first(where: { $0.sectionId == prevId }) {
          self.selectedSection = stillExists
        } else {
          self.selectedSection = fetchSection.first
        }

        self.isLoading = false
        print("강제 새로고침 완료")
      }
    } catch {
      await TaskTimeUtility.waitForMinimumLoadingTime(
        startTime: startTime
      )

      await MainActor.run {
        self.isLoading = false
        if self.videos.isEmpty {
          self.errorMsg = VideoError.fetchFailed.userMsg
        }
        print("강제 새로고침 실패: \(error)")
      }
    }
  }
  
  // 영상 삭제 메서드 Storage + Firestore(Video + Track)
  func deleteVideo(video: Video, tracksId: String) async {
    let startTime = Date()

    await MainActor.run {
      self.isLoading = true
      self.errorMsg = nil
    }

    do {
      let videoId = video.videoId.uuidString

      let videoPath = StorageType.video(videoId).path
      let thumbnailPath = StorageType.thumbnail(videoId).path

      try await withThrowingTaskGroup(of: Void.self) { group in
        group.addTask {
          _ = try await self.storage.deleteVideo(at: videoPath)
        }
        group.addTask {
          _ = try await self.storage.deleteVideo(at: thumbnailPath)
        }
        group.addTask {
          _ = try await self.deleteTrack(videoId: videoId, tracksId: tracksId)
        }
        group.addTask {
          _ = try await self.store.delete(collectionType: .video, documentID: videoId)
          print(videoId)
        }
        try await group.waitForAll()
      }

      // 캐시도 삭제
      await dataCacheManager.removeVideo(
        videoId: videoId,
        from: tracksId
      )

      // 최소 로딩 시간 보장 (스켈레톤 뷰 1.5초)
      await TaskTimeUtility.waitForMinimumLoadingTime(
        startTime: startTime
      )

      await MainActor.run {
        self.videos.removeAll { $0.videoId == video.videoId }
        self.track.removeAll { $0.videoId == videoId }
        self.isLoading = false
      }
    } catch {
      // 최소 로딩 시간 보장 (스켈레톤 뷰 1.5초)
      await TaskTimeUtility.waitForMinimumLoadingTime(
        startTime: startTime
      )

      await MainActor.run { // TODO: 에러 처리
        self.isLoading = false
        self.errorMsg = "영상 삭제에 실패했습니다. 다시 시도해 주세요."
      }
      print("영상 삭제 실패")
    }
  }
}
// MARK: - 파이어베이스 메서드 조건 쿼리 분리
private extension VideoListViewModel {
  func fetchSection(
    in tracksId: String
  ) async throws -> [Section] {
    return try await store.fetchAllFromSubcollection(
      under: .tracks,
      parentId: tracksId,
      subCollection: .section,
      orderBy: "created_at",
      descending: false
    )
  }
  
  func fetchTrack(
    in tracksId: String,
    withIn sectionId: String
  ) async throws -> [Track] {
    return try await store.fetchAllFromSubSubcollection(
      in: .tracks,
      grandParentId: tracksId,
      withIn: .section,
      parentId: sectionId,
      subCollection: .track
    )
  }
  
  func deleteTrack(
    videoId: String,
    tracksId: String
  ) async throws {
    let trackingTrack = track.filter { $0.videoId == videoId }
    
    for track in trackingTrack {
      try await self.store.deleteFromSubSubcollection(
        in: .tracks,
        grandParentId: tracksId,
        withIn: .section,
        parentId: track.sectionId,
        subCollection: .track,
        target: track.trackId
      )
      print(track.trackId)
    }
  }
}
// MARK: - 프리뷰
extension VideoListViewModel {
  static var preview: VideoListViewModel {
    let vm = VideoListViewModel()
    
    // 목 데이터 주입
    vm.section = [
      Section(sectionId: "1", sectionTitle: "기초"),
      Section(sectionId: "2", sectionTitle: "중급"),
      Section(sectionId: "3", sectionTitle: "고급 안무 연습")
    ]
    
    vm.track = [
      Track(trackId: "t1", videoId: "v1", sectionId: "1"),
      Track(trackId: "t2", videoId: "v2", sectionId: "1"),
      Track(trackId: "t3", videoId: "v3", sectionId: "2")
    ]
    
    vm.videos = [
      Video(
        videoId: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        videoTitle: "비디오 1",
        videoDuration: 120.5,
        videoURL: "https://example.com/video1.mp4",
        thumbnailURL: "https://example.com/thumb1.jpg",
        createdAt: Date()
      ),
      Video(
        videoId: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        videoTitle: "비디오 2",
        videoDuration: 95.3,
        videoURL: "https://example.com/video2.mp4",
        thumbnailURL: "https://example.com/thumb2.jpg",
        createdAt: Date()
      ),
      Video(
        videoId: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
        videoTitle: "비디오 3",
        videoDuration: 180.0,
        videoURL: "https://example.com/video3.mp4",
        thumbnailURL: "https://example.com/thumb3.jpg",
        createdAt: Date()
      )
    ]
    
    vm.isLoading = false
    
    return vm
  }
}
