//
//  Double+.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/15/25.
//

import Foundation

extension Double {
  func formattedTime() -> String {
    let m = Int(self) / 60
    let s = Int(self) % 60
    return String(format: "%02d:%02d", m, s)
  }
}
