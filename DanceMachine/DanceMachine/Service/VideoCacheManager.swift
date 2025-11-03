//
//  VideoCacheManager.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/27/25.
//

import Foundation
import AVFoundation
import ObjectiveC
import UIKit

actor VideoCacheManager {
  static let shared = VideoCacheManager()
  
  private init() {}
  
  // MARK: 캐시 경로
  private var videoCacheDirectory: URL {
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
  
  // MARK: 썸네일 캐시 경로
  private var thumbnailCacheDirectory: URL {
    let path = FileManager.default.urls(
      for: .documentDirectory,
      in: .userDomainMask
    )
    let thumbDir = path[0].appendingPathComponent(
      "thumbnails",
      isDirectory: true
    )
    if !FileManager.default.fileExists(atPath: thumbDir.path) {
      try? FileManager.default.createDirectory(
        at: thumbDir,
        withIntermediateDirectories: true
      )
    }
    return thumbDir
  }
  
  // MARK: 캐시된 비디오 url 가져오기
  func getCachedVideoURL(for videoId: String) -> URL? {
    let cachedURL = videoCacheDirectory.appendingPathComponent("\(videoId).mov")
    
    if FileManager.default.fileExists(atPath: cachedURL.path) {
      print("비디오 캐싱 url 찾: \(videoId)")
      return cachedURL
    }
    return nil
  }
  // MARK: 캐시된 썸네일 가져오기
  func getCachedThumbnailURL(for videoId: String) -> UIImage? {
    let cachedURL = thumbnailCacheDirectory.appendingPathComponent("\(videoId).jpg")
    
    if FileManager.default.fileExists(atPath: cachedURL.path),
       let data = try? Data(contentsOf: cachedURL),
       let image = UIImage(data: data) {
      print("썸네일 캐싱 url 찾: \(videoId)")
      return image
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
    
    let cachedURL = videoCacheDirectory.appendingPathComponent("\(videoId).mov")
    
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
  // MARK: 이미지 바로 캐시 저장
  func cacheThumbnailForImage(_ image: UIImage, videoId: String) async {
    let thumbDir = thumbnailCacheDirectory
    let thumbURL = thumbDir.appendingPathComponent("\(videoId).jpg")
    
    guard let jpegData = image.jpegData(compressionQuality: 0.8) else {
      return
    }
    
    do {
      try jpegData.write(to: thumbURL)
      print("썸네일 캐시 저장: \(videoId)")
    } catch {
      print("썸네일 캐시. ㅓ장 실패: \(error)")
    }
  }
  // MARK: 썸네일 다운로드 및 캐시 저장
  func downloadAndCacheThumbnail(
    from urlString: String,
    videoId: String
  ) async throws -> UIImage {
    guard let url = URL(string: urlString) else {
      throw URLError(.badURL)
    }
    print("썸네일 다운로드 시작: \(videoId)")
    
    let cachedURL = thumbnailCacheDirectory.appendingPathComponent("\(videoId).jpg")
    
    let request = URLRequest(url: url)
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpRespone = response as? HTTPURLResponse,
          httpRespone.statusCode == 200,
          let image = UIImage(data: data) else {
      throw URLError(.badServerResponse)
    }
    
    // 캐시 저장
    if let jpegData = image.jpegData(compressionQuality: 0.8) {
      try jpegData.write(to: cachedURL)
      print("썸네일 캐시 저장: \(videoId)")
    }
    return image
  }
  
  // MARK: 캐시 삭제 + 썸네일
  // TODO: 동영상 삭제에 추가 해야함
  func clearCache(for videoId: String) {
    let videoCachedURL = videoCacheDirectory.appendingPathComponent("\(videoId).mov")
    let thumbCachedURL = thumbnailCacheDirectory.appendingPathComponent("\(videoId).jpg")
    try? FileManager.default.removeItem(at: videoCachedURL)
    try? FileManager.default.removeItem(at: thumbCachedURL)
    print("캐시 삭제: \(videoId)")
  }
  
  // MARK: 전체 캐시 삭제
  // TODO: 전체 동영상이 삭제되는 케이스에 추가 (트랙 삭제, 곡삭제, 프로젝트 전체 삭제, 팀 삭제 등)
  func clearAllCache() {
    try? FileManager.default.removeItem(at: videoCacheDirectory)
    try? FileManager.default.removeItem(at: thumbnailCacheDirectory)
    print("전체 캐시 삭제")
  }
  
  // MARK: 캐시 용량 확인 MB로
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
    
    // 썸네일 캐시 용량
    if let thumbEnum = FileManager.default.enumerator(
      at: thumbnailCacheDirectory,
      includingPropertiesForKeys: [.fileSizeKey]
    ) {
      for case let fileURL as URL in thumbEnum {
        guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
              let fileSize = resourceValues.fileSize else { continue }
        totalSize += Int64(fileSize)
      }
    }
    
    return Double(totalSize) / 1_048_576 // MB로 반환
  }
}
