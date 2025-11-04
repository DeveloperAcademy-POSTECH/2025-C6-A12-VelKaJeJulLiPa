//
//  ListDataCacheManager.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/3/25.
//

import Foundation

actor VideoDataCacheManager {
  static let shared = VideoDataCacheManager()
  
  private init() {}
  
  // MARK: 캐시 경로
  private var cacheDirectory: URL {
    let path = FileManager.default.urls(
      for: .documentDirectory,
      in: .userDomainMask
    )
    let dataDir = path[0].appendingPathComponent(
      "listData",
      isDirectory: true
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
  
  struct CachedData: Codable {
    var videos: [Video]
    var track: [Track]
    var section: [Section]
    var lastUpdated: Date
  }
  
  // MARK: - 전체 데이터 캐시 저장
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
    
    let fileURL = cacheDirectory.appendingPathComponent("\(tracksId).json")
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    
    let jsonData = try encoder.encode(data)
    try jsonData.write(to: fileURL)
    
    print("캐싱 성공: \(tracksId) - videos: \(video.count), track: \(track.count), section: \(section.count)")
  }
  
  // MARK: 전체 데이터 조회
  func getCachedData(for tracksId: String) async -> CachedData? {
    let fileURL = cacheDirectory.appendingPathComponent("\(tracksId).json")

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
  // MARK: - 새 영상 추가
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
  // MARK: - 영상 삭제
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
  // MARK: - 특정 tracksId(곡 삭제?) 캐시 삭제
  func clearCache(for tracksId: String) {
    let fileURL = cacheDirectory.appendingPathComponent("\(tracksId).json")
    try? FileManager.default.removeItem(at: fileURL)
    print("캐시 삭제: \(tracksId)")
  }
  // MARK: - 전체 캐시 삭제 (팀 삭제??)
  func clearAllCache() {
    try? FileManager.default.removeItem(at: cacheDirectory)
    print("전체 캐시 삭제")
  }
  // MARK: - 캐시 용량 확인 (MB)
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
}

// MARK: - 영상 리스트 관련 데이터들 CRUD
extension VideoDataCacheManager {
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
      
      try? await cache(
        video: data.videos,
        track: data.track,
        section: data.section,
        for: tracksId
      )
      print("캐시에서 트랙 이동: \(trackId) → \(toSectionId)")
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
