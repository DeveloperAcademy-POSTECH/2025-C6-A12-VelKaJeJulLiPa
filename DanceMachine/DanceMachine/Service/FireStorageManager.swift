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
  private let customBucketURL = "gs://dancemachine-5243b.firebasestorage.app"
  
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
  func uploadStorage(
    data: Data,
    type: StorageType,
    progressHandler: ((Double) -> Void)? = nil,
    timeout: TimeInterval = 60.0
  ) async throws -> String {
    
    let path = type.path
    let ref = getStorageReference().child(path)
    
    return try await withThrowingTaskGroup(of: String.self) { group in
      // 업로드 태스크
      group.addTask {
        let uploadTask = ref.putData(data)
        
        // 진행률 관찰 (동기 작업)
        if let progressHandler = progressHandler {
          uploadTask.observe(.progress) { snapshot in
            guard let progress = snapshot.progress else { return }
            let percent = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
            Task { @MainActor in
              progressHandler(percent)
            }
          }
        }
        
        // 업로드 완료 대기 (continuation 사용)
        return try await withCheckedThrowingContinuation { continuation in
          uploadTask.observe(.success) { _ in
            print("스토리지 업로드 성공: \(path)")
            continuation.resume(returning: path)
          }
          
          uploadTask.observe(.failure) { snapshot in
            if let _ = snapshot.error {
              continuation.resume(throwing: VideoError.uploadFailed)
            } else {
              continuation.resume(throwing: VideoError.uploadFailed)
            }
          }
        }
      }
      // 타임아웃 태스크
      group.addTask {
        try await Task.sleep(for: .seconds(timeout))
        throw VideoError.uploadTimeout
      }
      
      guard let result = try await group.next() else {
        throw VideoError.uploadFailed
      }
      
      group.cancelAll()
      return result
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
