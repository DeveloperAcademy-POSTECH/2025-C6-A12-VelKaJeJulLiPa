//
//  TaskTimeUtility.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/3/25.
//

import Foundation

/// 스켈레톤 뷰 뜨는 시간을 보장해주는 유틸리티 구조체 입니다.
struct TaskTimeUtility {
  static func waitForMinimumLoadingTime(
    startTime: Date,
    minimim: TimeInterval = 1.0
  ) async {
    let elapedTime = Date().timeIntervalSince(startTime)
    if elapedTime < minimim {
      try? await Task.sleep(nanoseconds: UInt64(minimim - elapedTime) * 1_000_000_000)
    }
  }
}
