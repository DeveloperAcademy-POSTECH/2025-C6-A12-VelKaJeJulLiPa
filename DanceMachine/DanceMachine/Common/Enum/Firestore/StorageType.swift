//
//  StorageType.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/13/25.
//

import Foundation

// MARK: 스토리지 업로드 메서드 분기처리 (영상, 썸네일)
enum StorageType {
  case video(String)
  case thumbnail(String)
  case feedbackImage(String)
  
  var path: String {
    switch self {
    case .video (let videoId):
      return "video/\(videoId)/\(videoId).video.mov"
    case .thumbnail(let thumbId):
      return "video/\(thumbId)/\(thumbId).jpg"
    case .feedbackImage(let feedbackId):
      return "image/\(feedbackId)/\(feedbackId).jpg"
    }
  }
}
