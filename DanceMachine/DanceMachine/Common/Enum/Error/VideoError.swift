//
//  UploadError.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/13/25.
//

import Foundation

enum VideoError: Error {
  case thumbnailFailed          // 썸네일 업로드 실패
  case uploadFailed             // 단순 업로드 실패
  case createSectionFailed      // 섹션 생성 실패
  case fetchFailed              // 불러오기 실패
  case deleteFailed             // 삭제 실패
  case uploadTimeout            // 업로드 타임아웃 (시간 지정)
  case networkError             // 네트워크 연결 오류
  
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
    case .uploadTimeout:
      "업로드 시간 초과"
    case .networkError:
      "네트워크 연결 오류"
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
    case .uploadTimeout:
      "업로드 시간이 초과되었습니다.\n네트워크 연결을 확인하고 다시 시도해주세요."
    case .networkError:
      "네트워크 연결이 불안정합니다.\n다시 시도해주세요."
    }
  }
}
