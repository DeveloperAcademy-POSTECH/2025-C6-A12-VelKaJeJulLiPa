//
//  VideoProgressManager.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/3/25.
//

import Foundation

/// 비디오 업로드 and 다운로드 진행률 추적을 담당하는 매니저 입니다.
@Observable
final class VideoProgressManager {
  static let shared = VideoProgressManager()
  private init() {}
  
  var isUploading: Bool = false
  var uploadProgress: Double = 0.0
  
  var onUploadComplete: ((Video, Track) -> Void)? = nil
  
  func startUpload() {
    self.isUploading = true
    self.uploadProgress = 0.0
  }
  
  func updateProgress(_ progress: Double) {
    guard progress.isFinite, progress >= 0, progress <= 1 else {
      print("progress value 오류 : \(progress)")
      return
    }
    self.uploadProgress = progress
  }
  
  func finishUpload(video: Video, track: Track) {
    uploadProgress = 1.0
    
    onUploadComplete?(video, track)
    
//    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//      self.isUploading = false
//      self.uploadProgress = 0.0
//    }
    
    self.isUploading = false
    self.uploadProgress = 0.0
  }
}
