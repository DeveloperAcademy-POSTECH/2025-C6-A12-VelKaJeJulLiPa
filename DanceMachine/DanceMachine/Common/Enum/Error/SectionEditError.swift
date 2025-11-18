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
      return ""
    case .updateError:
      return ""
    case .deleteError:
      return ""
    }
  }
  
  var userMsg: String {
    switch self {
    case .createError:
      return ""
    case .updateError:
      return ""
    case .deleteError:
      return ""
    }
  }
}
