//
//  VideoCacheManager.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/27/25.
//

import Foundation
import AVFoundation
import ObjectiveC

/// 비디오 파일을 로컬 디스크에 캐싱하여 오프라인 재생을 지원하는 매니저 입니다.
///
/// **주요 기능:**
/// - 비디오 파일 다운로드 및 로컬 저장
/// - 캐시된 비디오 조회
/// - 다운로드 진행률 추적
/// - 자동 캐시 정리
///
/// **저장 위치:**
/// - 비디오: 'Documents/videos/{videoId}.mov'
///
/// **캐시 정리 정책:**
/// - 마지막 접근 후 2주가 지난 비디오 자동 삭제 (LRU)
/// - 앱 시작 시 및 백그라운드 진입 시 캐시 정리 로직 발동
///
/// **Thread Safety: **
/// - Actor 로 구현되어 있어 스레드 안전을 보장하였습니다.
actor VideoCacheManager {
  static let shared = VideoCacheManager()
  
  private init() {}
  
  // MARK: - Properties
  
  /// 비디오 캐시 저장 디렉토리
  ///
  /// **경로:** `Documents/videos/`
  ///
  /// **자동 생성:** 디렉토리가 없으면 자동으로 생성됩니다.
  private var videoCacheDirectory: URL {
    let path = FileManager.default.urls(
      for: .documentDirectory,
      in: .userDomainMask
    )
    
    let videoDir = path[0].appending(
      path: "vidoes",
      directoryHint: .isDirectory
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
  
  // MARK: - Public Methods
  
  /// 캐시된 비디오 파일의 로컬 URL을 반환하는 메서드 입니다.
  ///
  /// 비디오가 캐시되어 있으면 로컬 파일 URL을 반환하고,
  /// 없으면 nil을 반환합니다. 조회 시 파일의 접근 시간 (access time)이 자동으로 갱신됩니다.
  ///
  /// - Parameter videoId: 조회할 비디오의 고유 ID
  /// - Returns: 캐시된 비디오 파일의 로컬 URL, 캐시되지 않았으면 nil
  func getCachedVideoURL(for videoId: String) -> URL? {
    let cachedURL = videoCacheDirectory.appending(path: "\(videoId).mov", directoryHint: .notDirectory)
    
    if FileManager.default.fileExists(atPath: cachedURL.path) {
      print("비디오 캐싱 url 찾: \(videoId)")
      return cachedURL
    }
    return nil
  }
  
  /// 서버에서 비디오를 다운로드하여 로컬에 캐싱하는 메서드입니다.
  ///
  /// 다운로드 진행률을 실시간으로 추적할 수 있으며,
  /// 다운로드 완료 후 파일은 자동으로 로컬 캐시에 저장됩니다.
  ///
  /// - Parameters:
  ///   - urlString: 다운로드할 비디오의 서버 URL
  ///   - videoId: 비디오의 고유 ID (캐시 파일명으로 사용함)
  ///   - progressHandler: 다운로드 진행률 콜백
  ///
  /// - Returns: 캐시된 비디오 파일의 로컬 URL
  func downloadAndCacheVideo(
    from urlString: String,
    videoId: String,
    progressHandler: @escaping (Double) -> Void
  ) async throws -> URL {
    guard let url = URL(string: urlString) else {
      throw VideoError.fetchFailed
    }
    
    print("비디오 다운로드 시작: \(videoId)")
    
    let cachedURL = videoCacheDirectory.appending(path: "\(videoId).mov", directoryHint: .notDirectory)
    
    // URLSessionDownloadTask로 진행률 추적
    return try await withCheckedThrowingContinuation { continuation in
      let session = URLSession.shared
      let task = session.downloadTask(with: url) { tempURL, response, error in
        if let error = error {
          continuation.resume(throwing: error)
          return
        }
        
        guard let tempURL = tempURL,
              let http = response as? HTTPURLResponse,
              http.statusCode == 200 else {
          continuation.resume(throwing: URLError(.badServerResponse))
          return
        }
        
        do {
          // 기존 파일 삭제
          if FileManager.default.fileExists(atPath: cachedURL.path) {
            try FileManager.default.removeItem(at: cachedURL)
          }
          // 임시 파일을 캐시 위치로 이동
          try FileManager.default.moveItem(at: tempURL, to: cachedURL)
          
          print("비디오 캐시 저장완료: \(videoId)")
          continuation.resume(returning: cachedURL)
        } catch {
          Task { @MainActor in await self.cleanupOldCache() }
          print("용량 부족으로 캐시 정리 후 다시 시도합니다.")
          do { try FileManager.default.moveItem(at: tempURL, to: cachedURL) } catch {
            print("저장 공간이 너무 적습니다.")
          }
          continuation.resume(throwing: error)
        }
      }
      
      // 진행률 관찰
      let observation = task.progress.observe(\.fractionCompleted) { progress, _ in
        Task { @MainActor in
          progressHandler(progress.fractionCompleted)
        }
      }
      
      // observation을 강하게 참조해야 함 (안 그러면 관찰이 중단됨)
      // task와 함께 유지되도록 objc_setAssociatedObject 사용
      objc_setAssociatedObject(
        task,
        "progressObservation",
        observation,
        .OBJC_ASSOCIATION_RETAIN
      )
      
      task.resume()
    }
  }
  
  /// 특정 비디오의 캐시를 삭제합니다.
  ///
  /// - Parameters:
  ///   - videoId: 삭제할 비디오ID
  func clearCache(for videoId: String) {
    let videoCachedURL = videoCacheDirectory.appending(path: "\(videoId).mov", directoryHint: .notDirectory)
    try? FileManager.default.removeItem(at: videoCachedURL)
    print("캐시 삭제: \(videoId)")
  }
  
  /// 모든 비디오 캐시를 삭제합니다.
  ///
  /// **사용 시나리오:**
  /// - 팀 삭제 시
  /// - 프로젝트 전체 삭제 시
  /// - 사용자가 수동으로 캐시 정리 요청 시
  func clearAllCache() {
    try? FileManager.default.removeItem(at: videoCacheDirectory)
    print("전체 캐시 삭제")
  }
  
  /// 현재 캐시된 비디오 파일들의 총 용량을 MB 단위로 반환합니다.
  ///
  /// - Returns: 캐시 총 용량 (MB)
  func getCacheSize() -> Double {
    var totalSize: Int64 = 0
    
    // 비디오 캐시 용량
    if let videoEnum = FileManager.default.enumerator(
      at: videoCacheDirectory,
      includingPropertiesForKeys: [.fileSizeKey]
    ) {
      for case let fileURL as URL in videoEnum {
        guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
              let fileSize = resourceValues.fileSize else { continue }
        totalSize += Int64(fileSize)
      }
    }
    return Double(totalSize) / 1_048_576 // MB로 반환
  }
  
  /// 오래된 비디오 캐시를 자동으로 정리합니다.
  ///
  /// **정리 기준:**
  /// - 마지막 접근(재생) 후 2주가 지난 비디오 파일 삭제
  ///
  /// **실행 시점:**
  /// - 앱 시작 시
  /// - 백그라운드 진입 시
  ///
  /// **LRU (Least Recently Used):**
  /// - 가장 최근에 사용하지 않은 파일부터 삭제
  /// - 파일의 contentAccessDate기준
  /// - 자주보는 영상은 자동으로 보존
  func cleanupOldCache() {
    let twoWeeksAgo = Date().addingTimeInterval(-14 * 24 * 3600)  // 2주

    print("[VideoCacheManager] 캐시 정리 시작...")

    guard let enumerator = FileManager.default.enumerator(
      at: videoCacheDirectory,
      includingPropertiesForKeys: [.contentAccessDateKey]
    ) else {
      print("[VideoCacheManager] enumerator 생성 실패")
      return
    }

    var deletedCount = 0

    for case let fileURL as URL in enumerator {
      guard let resourceValues = try? fileURL.resourceValues(forKeys: [.contentAccessDateKey]),
            let accessDate = resourceValues.contentAccessDate,
            accessDate < twoWeeksAgo else { continue }

      try? FileManager.default.removeItem(at: fileURL)
      deletedCount += 1
      print("오래된 비디오 캐시 삭제: \(fileURL.lastPathComponent)")
    }

    print("[VideoCacheManager] 정리 완료 - 삭제된 파일: \(deletedCount)개")
  }
}
