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
  
  // 영상 제목 수정 메서드 Firestore(Video)
  func updateVideoTitle(
    video: Video,
    newTitle: String,
    tracksId: String
  ) async {
    await MainActor.run {
      self.isLoading = true
      self.errorMsg = nil
    }

    do {
      let videoId = video.videoId.uuidString

      // Firestore에 비디오 제목 업데이트
      try await store.updateFields(
        collection: .video,
        documentId: videoId,
        asDictionary: ["video_title": newTitle]
      )
      print("\(videoId)의 영상 제목 \(newTitle)로 변경 완료")
      
      // TODO: 캐시도 업데이트 해야함. #37 브랜치 머지 된 이후
      await dataCacheManager.updateVideoTitle(
        videoId: video.videoId.uuidString,
        newTitle: newTitle,
        in: tracksId
      )

      // 로컬 UI 업데이트
      await MainActor.run {
        if let index = self.videos.firstIndex(where: { $0.videoId == video.videoId }) {
          var updatedVideo = self.videos[index]
          updatedVideo.videoTitle = newTitle
          self.videos[index] = updatedVideo
        }
        self.isLoading = false
      }

      // 제목 수정 완료 토스트 알림
      NotificationCenter.default.post(name: .showEditVideoTitleToast, object: nil)
      print("비디오 제목 업데이트 성공: \(newTitle)")
    } catch {
      await MainActor.run {
        self.isLoading = false
        self.errorMsg = "영상 제목 수정에 실패했습니다. 다시 시도해 주세요."
      }
      print("영상 제목 수정 실패: \(error)")
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

      // 삭제 완료 토스트 알림
      NotificationCenter.default.post(name: .showDeleteToast, object: nil)
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
