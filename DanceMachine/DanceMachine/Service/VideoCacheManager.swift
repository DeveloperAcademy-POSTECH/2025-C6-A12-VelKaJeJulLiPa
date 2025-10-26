//
//  VideoCacheManager.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/27/25.
//

import Foundation
import AVFoundation

actor VideoCacheManager {
  static let shared = VideoCacheManager()
  
  private init() {}
  
  // MARK: 캐시 경로
  private var cacheDirectory: URL {
    let path = FileManager.default.urls(
      for: .documentDirectory,
      in: .userDomainMask
    )
    let videoDir = path[0].appendingPathComponent(
      "videos",
      isDirectory: true
    )
    // 디렉토리 없으면 새로 생성
    if !FileManager.default.fileExists(atPath: videoDir.path) {
      try? FileManager.default.createDirectory(
        at: videoDir,
        withIntermediateDirectories: true
      )
    }
    return videoDir
  }
  
  // MARK: 캐시된 비디오 url 가져오기
  func getCachedVideoURL(for videoId: String) -> URL? {
    let cachedURL = cacheDirectory.appendingPathComponent("\(videoId).mov")
    
    if FileManager.default.fileExists(atPath: cachedURL.path) {
      print("비디오 캐싱 url 찾: \(videoId)")
      return cachedURL
    }
    return nil
  }
  
  // MARK: 비디오 다운로드 및 캐시 저장 + 진행률
  func downloadAndCacheVideo(
    from urlString: String,
    videoId: String,
    progressHandler: @escaping (Double) -> Void
  ) async throws -> URL {
    guard let url = URL(string: urlString) else {
      throw URLError(.badURL)
    }
    
    print("비디오 다운로드 시작: \(videoId)")
    
    // URLSession으로 다운로드
    let (data, response) = try await URLSession.shared.data(from: url)
    
    guard let http = response as? HTTPURLResponse,
          http.statusCode == 200 else {
      throw URLError(.badServerResponse)
    }
    
    let cachedURL = cacheDirectory.appendingPathComponent("\(videoId).mov")
    
    try data.write(to: cachedURL)
    
    print("비디오 캐시 저장완료: \(videoId)")
    return cachedURL
  }
  
  // MARK: 캐시 삭제
  func clearCache(for videoId: String) {
    let cachedURL = cacheDirectory.appendingPathComponent("\(videoId).mov")
    try? FileManager.default.removeItem(at: cachedURL)
    print("캐시 삭제: \(videoId)")
  }
  
  // MARK: 전체 캐시 삭제
  func clearAllCache() {
    try? FileManager.default.removeItem(at: cacheDirectory)
    print("전체 캐시 삭제")
  }
  
  // MARK: 캐시 용량 확인 MB로
  func getCacheSize() -> Double {
    guard let enumerator = FileManager.default.enumerator(
      at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
    
    var totalSize: Int64 = 0
    
    for case let fileURL as URL in enumerator {
      guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
            let fileSize = resourceValues.fileSize else { continue }
      totalSize += Int64(fileSize)
    }
    return Double(totalSize) // 1_048_579 // MB로 반환
  }
}
