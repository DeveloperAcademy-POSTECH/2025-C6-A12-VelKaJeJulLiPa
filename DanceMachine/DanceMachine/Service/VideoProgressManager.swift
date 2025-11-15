//
//  VideoProgressManager.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/3/25.
//

import Foundation

/// 비디오 업로드 상태 관리
@Observable
final class VideoProgressManager {
  static let shared = VideoProgressManager()
  private init() {}

  enum UploadState {
    case idle
    case uploading(progress: Double)
    case failed(message: String)
    case compressing(progress: Double)
    case fileToLarge(message: String)
  }
  
  func fileTooLarge(message: String) {
    uploadState = .fileToLarge(message: message)
  }

  var uploadState: UploadState = .idle
  
  func startCompressing() {
    uploadState = .compressing(progress: 0.0)
  }
  
  func updatedCompressionProgress(_ progress: Double) {
    guard progress.isFinite, progress >= 0, progress <= 1 else { return }
    uploadState = .compressing(progress: progress)
  }

  func startUpload() {
    uploadState = .uploading(progress: 0.0)
  }

  func updateProgress(_ progress: Double) {
    guard progress.isFinite, progress >= 0, progress <= 1 else { return }
    uploadState = .uploading(progress: progress)
  }

  func finishUpload() {
    uploadState = .idle
  }

  func failUpload(message: String) {
    uploadState = .failed(message: message)
  }

  func reset() {
    uploadState = .idle
  }
}
