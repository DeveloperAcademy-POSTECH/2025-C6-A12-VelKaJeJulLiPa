//
//  SectionEditError.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/18/25.
//

import Foundation

enum SectionEditError: Error {
  case createError
  case updateError
  case deleteError
  
  var debugMsg: String {
    switch self {
    case .createError:
      return "섹션 생성 에러"
    case .updateError:
      return "섹션 수정 에러"
    case .deleteError:
      return "섹션 삭제 에러"
    }
  }
  
  var userMsg: String {
    switch self {
    case .createError:
      return "파트를 생성하는 중에 문제가 발생했습니다.\n네트워크 확인 후 다시 시도해 주세요."
    case .updateError:
      return "파트를 수정하는 중에 문제가 발생했습니다.\n네트워크 확인 후 다시 시도해 주세요."
    case .deleteError:
      return "파트를 삭제하는 중에 문제가 발생했습니다.\n네트워크 확인 후 다시 시도해 주세요."
    }
  }
}
