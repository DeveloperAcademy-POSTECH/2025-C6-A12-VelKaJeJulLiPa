//
//  Date+.swift
//  DanceMachine
//
//  Created by Paidion on 10/25/25.
//

import Foundation


extension Date {
    /// 특정 시각이 현재 시각으로부터 5분을 넘었는지 판별하는 메서드
  func isWithinPast(minutes: Int) -> Bool {
    let now = Date.now
    let timeAgo = Date.now.addingTimeInterval(-1 * TimeInterval(60 * minutes))
    let range = timeAgo...now
    return range.contains(self)
  }
}

