//
//  MemberError.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/19/25.
//

import Foundation

enum MemberError: Error {
  case fetchFailed
  
  var debugMsg: String {
    switch self {
    case .fetchFailed:
      return "멤버 패치 실패"
    }
  }
  
  var userMsg: String {
    switch self {
    case .fetchFailed:
      return "팀 멤버를 불러오는 데 실패했습니다.\n잠시 후에 다시 시도해 주세요."
    }
  }
}
