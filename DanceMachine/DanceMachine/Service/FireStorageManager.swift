//
//  FireStorageManager.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/8/25.
//

import Foundation
import FirebaseStorage

final class FireStorageManager {
  static let shared = FireStorageManager()
  private init() {}
  
  // MARK: 버킷 링크
  // TODO: 버킷 단일리전으로 생성 후 경로 지정
  private let customBucketURL = ""
  
  private func getStorageReference() -> StorageReference {
    return Storage.storage(url: customBucketURL).reference()
  }
  
  // MARK: - path -> url로 변환하는 메서드
  func getDownloadURL(for path: String) async throws -> String {
    let storageRef = getStorageReference().child(path)
    let url = try await storageRef.downloadURL()
    return url.absoluteString
  }
  // MARK: - 스토리지에 업로드하는 메서드
  func uploadVideo(data: Data, videoId: UUID) async throws -> String {
    
    let path = "video/\(videoId)/video.mov"
    
    do {
      let ref = getStorageReference().child(path)
      let _ = try await ref.putDataAsync(data)
      print("비디오 업로드 성공")
      return path
    } catch {
      throw FirestoreError.addFailed(underlying: error)
    }
  }
  // MARK: - 스토리지에서 동영상 삭제하는 메서드
  func deleteVideo(at path: String) async throws -> Bool {
    do {
      let ref = getStorageReference().child(path)
      try await ref.delete()
      print("비디오 삭제 성공: \(path)")
      return true
    } catch {
      throw FirestoreError.deleteFailed(underlying: error)
    }
  }
}
