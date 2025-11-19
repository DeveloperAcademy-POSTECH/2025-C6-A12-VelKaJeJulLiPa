//
//  FeedbackError.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/19/25.
//

import Foundation

enum FeedbackError: Error {
  case fetchFeedbackFailed
  case fetchReplyFailed
  
  var debugMsg: String {
    switch self {
    case .fetchFeedbackFailed:
      return "피드백 불러오기 실패"
    case .fetchReplyFailed:
      return "댓글 불러오기 실패"
    }
  }
  
  var userMsg: String {
    switch self {
    case .fetchFeedbackFailed:
      return "피드백 불러오기를 실패했습니다.\n네트워크를 확인해주세요."
    case .fetchReplyFailed:
      return "댓글 불러오기를 실패했습니다.\n네트워크를 확인해주세요."
    }
  }
}
