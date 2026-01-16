//
//  String+.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/8/25.
//

import Foundation

extension String {
  func sanitized(limit: Int) -> String {
    var result = self
    
    // Prevent leading space as the first character
    if result.first == " " {
      result = String(result.drop(while: { $0 == " " })) // ❗️공백 금지
    }
    
    // Enforce 20-character limit
    if result.count > limit {
      result = String(result.prefix(limit)) // ❗️20글자 초과 금지
    }
    
    return result
  }
}
