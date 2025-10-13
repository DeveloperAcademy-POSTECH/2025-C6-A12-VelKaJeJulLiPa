//
//  UploadError.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/13/25.
//

import Foundation

enum VideoError: Error {
  case thumbnailFailed
  case uploadFailed
  case createSectionFailed
  case fetchFailed
  case deleteFailed
  
  var debugMsg: String {
    switch self {
    case .thumbnailFailed: 
      "썸네일 생성에 실패했습니다."
    case .uploadFailed:
      "비디오 업로드에 실패했습니다."
    case .createSectionFailed: 
      "영상 정보 저장에 실패했습니다."
    case .fetchFailed:
      "비디오 목록을 불러오는데 실패했습니다."
    case .deleteFailed:
      "비디오 삭제에 실패했습니다."
    }
  }
  
  var userMsg: String {
    switch self {
    case .thumbnailFailed:
      "동영상 처리 중 문제가 발생했습니다.\n다시 시도해주세요."
    case .uploadFailed:
      "네트워크 연결을 확인하고\n다시 시도해주세요."
    case .createSectionFailed:
      "일시적인 오류가 발생했습니다.\n잠시 후 다시 시도해주세요."
    case .fetchFailed:
      "영상 목록을 불러올 수 없습니다.\n네트워크 연결을 확인해주세요."
    case .deleteFailed:
      "영상 삭제에 실패했습니다.\n다시 시도해주세요."
    }
  }
}
