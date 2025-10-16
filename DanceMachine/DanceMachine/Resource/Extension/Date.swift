//
//  Date.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/15/25.
//

import Foundation

extension Date {
  func formattedDate() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy년 MM월 dd일"
    return formatter.string(from: self)
  }
}
