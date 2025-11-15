//
//  ListDataCacheManager.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/3/25.
//

import Foundation

/// 곡 (Tracks)에 속한 video, track, section 데이터들을 JSON으로 캐싱하는 Actor 기반 매니저 입니다.
///
/// **주요 기능:**
/// - 영상 리스트 메타데이터 JSON 캐싱
/// - 서버 조회 없이 로컬에서 즉시 UI 업데이트도 진행합니다.
/// - 5분 TTL(Time To Live) 기반 캐시 만료 방식
/// - LRU 방식의 자동 캐시 정리
///
/// **저장 위치:**
/// - 메타데이터 : `Documents/listData/{tracksId}.json`
///
/// **캐시 구조:**
/// ```json
/// {
///   "videos": [Video],
///   "track": [Track],
///   "section": [Section],
///   "lastUpdated": "2025-01-15T12:30:00Z",
///   "lastAccessedDate": "2025-01-15T12:35:00Z"
/// }
/// ```
///
/// **캐시 정리 정책:**
/// - 마지막 접근 후 2개월이 지난 데이터 자동 삭제 (LRU)
/// - 앱 시작 시 및 백그라운드 진입 시 자동 정리
actor ListDataCacheManager {
  static let shared = ListDataCacheManager()
  
  private init() {}
  
  // MARK: - Properties
  
  /// 캐시 저장 디렉토리
  ///
  /// **경로:** `Documents/listData/`
  ///
  /// **자동 생성:** 디렉토리가 없으면 자동으로 생성됩니다.
  private var cacheDirectory: URL {
    let path = FileManager.default.urls(
      for: .documentDirectory,
      in: .userDomainMask
    )
    let dataDir = path[0].appending(
      path: "listData",
      directoryHint: .isDirectory
    )
    // 디렉토리 없으면 새로 생성
    if !FileManager.default.fileExists(atPath: dataDir.path) {
      try? FileManager.default.createDirectory(
        at: dataDir,
        withIntermediateDirectories: true
      )
    }
    return dataDir
  }
  
  /// 캐시 데이터 구조체
  ///
  /// **필드:**
  /// - videos: 비디오 메타데이터 배열
  /// - track: 트랙 데이터 배열 (비디오-섹션 매핑)
  /// - section: 섹션 데이터 배열
  /// - lastUpdated: 마지막 서버 업데이트 시간 (캐시 만료 판단용)
  ///
  /// **Codable:** JSON 인코딩/디코딩 지원
  struct CachedData: Codable {
    var videos: [Video]
    var track: [Track]
    var section: [Section]
    var lastUpdated: Date
  }
  
  // MARK: - Public Methods
  
  /// 전체 데이터를 JSON으로 캐싱합니다.
  ///
  /// - Parameters:
  ///   - video: 비디오 메타데이터 배열
  ///   - track: 트랙 데이터 배열
  ///   - section: 섹션 데이터 배열
  ///   - tracksId: 곡 (Tracks) 고유 ID
  func cache(
    video: [Video],
    track: [Track],
    section: [Section],
    for tracksId: String
  ) async throws {
    let data = CachedData(
      videos: video,
      track: track,
      section: section,
      lastUpdated: Date()
    )
    
    let fileURL = cacheDirectory.appending(path: "\(tracksId).json", directoryHint: .notDirectory)
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    
    let jsonData = try encoder.encode(data)
    
    do {
      try jsonData.write(to: fileURL)
    } catch {
      self.cleanupOldCache()
      print("용량 부족으로 캐시 정리 후 다시 시도합니다.")
      do { try jsonData.write(to: fileURL) } catch {
        print("저장 공간이 너무 적습니다.")
      }
    }
    
    print("캐싱 성공: \(tracksId) - videos: \(video.count), track: \(track.count), section: \(section.count)")
  }
  
  /// 캐시된 데이터를 조회합니다.
  ///
  /// **캐시 만료 조건:**
  /// 1. 파일이 존재하지 않음
  /// 2. section 데이터가 비어있음
  /// 3. 마지막 업데이트 후 5분 경과
  ///
  /// - Parameters:
  ///   - tracksId: 곡 (Tracks) 고유 ID
  /// - Returns: 캐시된 데이터, 없거나 만료되없으면 nil
  ///
  /// **TTL (Time To Live):** 5분
  func getCachedData(for tracksId: String) async -> CachedData? {
    let fileURL = cacheDirectory.appending(path: "\(tracksId).json", directoryHint: .notDirectory)

    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      print("캐시 파일 없음: \(tracksId)")
      return nil
    }

    do {
      let jsonData = try Data(contentsOf: fileURL)
      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601

      let data = try decoder.decode(CachedData.self, from: jsonData)

      // 캐시 데이터가 실제로 있는지 확인 (section은 필수, videos는 선택)
      guard !data.section.isEmpty else {
        print("캐시 데이터 비어있음: \(tracksId)")
        return nil
      }

      // 캐시 만료 확인 (5분 = 300초)
      let cacheAge = Date().timeIntervalSince(data.lastUpdated)
      let cacheExpirationTime: TimeInterval = 300 // 5분

      if cacheAge > cacheExpirationTime {
        print("캐시 만료됨: \(tracksId) - 마지막 업데이트: \(Int(cacheAge))초 전")
        return nil
      }

      print("캐시 로드 성공: \(tracksId) - videos: \(data.videos.count), section: \(data.section.count)")
      return data
    } catch {
      print("캐시 로드 실패: \(error)")
      return nil
    }
  }
  /// 새 영상을 캐시에 추가하는 메서드입니다. UI 즉각 반영을 위함
  func addVideo(
    _ video: Video,
    track: Track,
    to tracksId: String
  ) async {
    guard var data = await getCachedData(for: tracksId) else {
      print("캐시 없음: \(tracksId)")
      return
    }
    
    // 중복 체크
    if !data.videos.contains(where: { $0.videoId == video.videoId }) {
      data.videos.insert(video, at: 0) // 맨 앞으로 추가
      data.track.append(track)
      data.lastUpdated = Date()
      
      try? await cache(
        video: data.videos,
        track: data.track,
        section: data.section,
        for: tracksId
      )
      print("캐시에 영상 추가: \(video.videoTitle)")
    }
  }
  /// 영상을 캐시에서 삭제하는 메서드 입니다. UI 즉각 반영을 위함
  func removeVideo(
    videoId: String,
    from tracksId: String
  ) async {
    guard var data = await getCachedData(for: tracksId) else { return }
    
    data.videos.removeAll { $0.videoId.uuidString == videoId }
    data.track.removeAll { $0.videoId == videoId }
    data.lastUpdated = Date()
    
    try? await cache(
      video: data.videos,
      track: data.track,
      section: data.section,
      for: tracksId
    )
    print("캐시에서 영상 삭제: \(videoId)")
  }
  /// 특정 캐시를 삭제합니다.
  ///
  /// - Parameters:
  ///   - tracksId: 삭제할 비디오ID
  func clearCache(for tracksId: String) {
    let fileURL = cacheDirectory.appending(path: "\(tracksId).json", directoryHint: .notDirectory)
    try? FileManager.default.removeItem(at: fileURL)
    print("캐시 삭제: \(tracksId)")
  }
  /// 모든 리스트 캐시를 삭제합니다.
  ///
  /// **사용 시나리오:**
  /// - 팀 삭제 시
  /// - 프로젝트 전체 삭제 시
  /// - 사용자가 수동으로 캐시 정리 요청 시
  func clearAllCache() {
    try? FileManager.default.removeItem(at: cacheDirectory)
    print("전체 캐시 삭제")
  }
  /// 현재 캐시된 파일들의 총 용량을 MB 단위로 반환합니다.
  ///
  /// - Returns: 캐시 총 용량 (MB)
  func getCacheSize() -> Double {
    guard let enumerator = FileManager.default.enumerator(
      at: cacheDirectory,
      includingPropertiesForKeys: [.fileSizeKey]
    ) else { return 0 }
    
    var totalSize: Int64 = 0
    
    for case let fileURL as URL in enumerator {
      guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
            let fileSize = resourceValues.fileSize else { continue }
      totalSize += Int64(fileSize)
    }
    
    return Double(totalSize) / 1_048_576  // MB로 반환
  }
  
  /// 오래된 영상 리스트 캐시를 자동으로 정리합니다.
  ///
  /// **정리 기준:**
  /// - 마지막 접근(재생) 후 2주가 지난 영상 리스트 캐시 파일 삭제
  ///
  /// **실행 시점:**
  /// - 앱 시작 시
  /// - 백그라운드 진입 시
  ///
  /// **LRU (Least Recently Used):**
  /// - 가장 최근에 사용하지 않은 파일부터 삭제
  /// - 파일의 contentAccessDate기준
  /// - 자주 들어오는 영상 리스트는 자동으로 보존
  func cleanupOldCache() {
    let twoWeeksAgo = Date().addingTimeInterval(-14 * 24 * 3600)  // 2주

    print("[VideoDataCacheManager] 캐시 정리 시작...")

    guard let enumerator = FileManager.default.enumerator(
      at: cacheDirectory,
      includingPropertiesForKeys: [.contentAccessDateKey]
    ) else {
      print("[VideoDataCacheManager] enumerator 생성 실패")
      return
    }

    var deletedCount = 0

    for case let fileURL as URL in enumerator {
      guard let resourceValues = try? fileURL.resourceValues(forKeys: [.contentAccessDateKey]),
            let accessDate = resourceValues.contentAccessDate,
            accessDate < twoWeeksAgo else { continue }

      try? FileManager.default.removeItem(at: fileURL)
      deletedCount += 1
      print("오래된 tracks 캐시 삭제: \(fileURL.lastPathComponent)")
    }

    print("[VideoDataCacheManager] 정리 완료 - 삭제된 파일: \(deletedCount)개")
  }
}

// MARK: - 영상 리스트 관련 데이터들 CRUD
extension ListDataCacheManager {
  // MARK: - Video 제목 수정
  func updateVideoTitle(
    videoId: String,
    newTitle: String,
    in tracksId: String
  ) async {
    guard var data = await getCachedData(for: tracksId) else { return }
    
    if let index = data.videos.firstIndex(where: { $0.videoId.uuidString == videoId }) {
      var updatedVideo = data.videos[index]
      updatedVideo.videoTitle = newTitle
      data.videos[index] = updatedVideo
      data.lastUpdated = Date()
      
      try? await cache(
        video: data.videos,
        track: data.track,
        section: data.section,
        for: tracksId
      )
      print("캐시에서 영상 제목 수정: \(newTitle)")
    }
  }
  // MARK: - Track 섹션 이동
  func moveTrack(
    trackId: String,
    toSectionId: String,
    in tracksId: String
  ) async {
    guard var data = await getCachedData(for: tracksId) else { return }
    
    if let index = data.track.firstIndex(where: { $0.trackId == trackId }) {
      var updatedTrack = data.track[index]
      updatedTrack.sectionId = toSectionId
      data.track[index] = updatedTrack
      data.lastUpdated = Date()

      do {
        try await cache(
          video: data.videos,
          track: data.track,
          section: data.section,
          for: tracksId
        )
        print("캐시에서 트랙 이동 성공: \(trackId) → \(toSectionId)")
      } catch {
        print("캐시 저장 실패: \(error)")
      }
    } else {
      print("캐시에서 트랙을 찾을 수 없음: \(trackId)")
    }
  }
  // MARK: - Section 추가
  func addSection(
    _ section: Section,
    to tracksId: String
  ) async {
    guard var data = await getCachedData(for: tracksId) else { return }
    
    if !data.section.contains(where: { $0.sectionId == section.sectionId }) {
      data.section.append(section)
      data.lastUpdated = Date()
      
      try? await cache(
        video: data.videos,
        track: data.track,
        section: data.section,
        for: tracksId
      )
      print("캐시에 섹션 추가: \(section.sectionTitle)")
    }
  }
  // MARK: - Section 삭제 (하위 video와 track도 함께 삭제)
  func removeSectionWithVideos(
    sectionId: String,
    from tracksId: String
  ) async {
    guard var data = await getCachedData(for: tracksId) else { return }

    // 1. 해당 섹션의 track들 찾기
    let tracksToDelete = data.track.filter { $0.sectionId == sectionId }
    let videoIdsToDelete = Set(tracksToDelete.map { $0.videoId })

    // 2. track 삭제
    data.track.removeAll { $0.sectionId == sectionId }

    // 3. video 삭제 (해당 video가 다른 섹션에 없는 경우만)
    for videoId in videoIdsToDelete {
      let stillExists = data.track.contains { $0.videoId == videoId }
      if !stillExists {
        data.videos.removeAll { $0.videoId.uuidString == videoId }
      }
    }

    // 4. section 삭제
    data.section.removeAll { $0.sectionId == sectionId }
    data.lastUpdated = Date()

    try? await cache(
      video: data.videos,
      track: data.track,
      section: data.section,
      for: tracksId
    )
    print("캐시에서 섹션과 하위 데이터 삭제: \(sectionId)")
  }
  // MARK: - Section 제목 수정
  func updateSectionTitle(
    sectionId: String,
    newTitle: String,
    in tracksId: String
  ) async {
    guard var data = await getCachedData(for: tracksId) else { return }
    
    if let index = data.section.firstIndex(where: { $0.sectionId == sectionId }) {
      var updatedSection = data.section[index]
      updatedSection.sectionTitle = newTitle
      data.section[index] = updatedSection
      data.lastUpdated = Date()
      
      try? await cache(
        video: data.videos,
        track: data.track,
        section: data.section,
        for: tracksId
      )
      print("캐시에서 섹션 제목 수정: \(newTitle)")
    }
  }
}
