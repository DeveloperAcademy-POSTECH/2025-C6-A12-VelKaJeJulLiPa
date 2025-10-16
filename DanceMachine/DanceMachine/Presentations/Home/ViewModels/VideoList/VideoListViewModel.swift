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
  
  var videos: [Video] = []
  var section: [Section] = []
  var track: [Track] = []
  
  var isLoading: Bool = false
  var errorMsg: String? = nil
  
  var selectedSection: Section? = nil
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
    #if DEBUG
    if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
      return }
    #endif
    await MainActor.run {
      self.isLoading = true
      self.errorMsg = nil
    }
    
    do {
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
      
      var fetchedVideos: [Video] = []
      // 4. 수집한 videoId로 Video 문서들 가져오기
      for videoId in videoIds {
        let video: Video = try await store.get(videoId, from: .video)
        print("수집한 개별 videoID: \(videoId)")
        fetchedVideos.append(video)
        fetchedVideos.sort {
          ($0.createdAt ?? .distantPast > ($1.createdAt ?? .distantPast))
        }
      }
      // 5. UI 업데이트
      await MainActor.run {
        self.section = fetchSection
        self.track = allTrack
        self.videos = fetchedVideos
        self.isLoading = false
      }
    } catch {
      await MainActor.run {
        self.isLoading = false
        self.errorMsg = VideoError.fetchFailed.userMsg
        print("비디오 에러: \(VideoError.fetchFailed.debugMsg)")
        print("상세 에러: \(error)")
      }
    }
  }
}
// MARK: - 파이어베이스 메서드 조건 쿼리 분리
private extension VideoListViewModel {
  func fetchSection(
    in tracksId: String
  ) async throws-> [Section] {
    return try await store.fetchAllFromSubcollection(
      under: .tracks,
      parentId: tracksId,
      subCollection: .section,
      orderBy: "created_at",
      descending: true
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
}
