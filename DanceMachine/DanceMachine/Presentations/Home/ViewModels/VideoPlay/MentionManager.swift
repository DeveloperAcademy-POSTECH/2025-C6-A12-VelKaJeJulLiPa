//
//  MentionManager.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/28/25.
//

import Foundation
import UIKit
import SwiftUI

/// 커스텀 텍스트 필드를 쓰는 뷰에서 사용하는 매니저 입니다.
@Observable
final class MentionManager {
  
  var showPicker: Bool = false
  var mentionQuery: String = ""
  
  var taggedUsers: [User] = []
  
  // MARK: @감지
  func handleMention(oldValue: String, newValue: String) {
    if newValue.last == "@" {
      self.showPicker = true
      self.mentionQuery = ""
    } else if showPicker {
      if let lastAtIndex = newValue.lastIndex(of: "@") {
        let queryStartIndex = newValue.index(after: lastAtIndex)
        if queryStartIndex < newValue.endIndex {
          mentionQuery = String(newValue[queryStartIndex...])
          // 공백 또는 줄바꿈 입력 시 멘션 피커 닫음
          if mentionQuery.contains(" ") || mentionQuery.contains("\n") {
            self.showPicker = false
            self.mentionQuery = ""
          }
        }
      } else {
        self.showPicker = false
        self.mentionQuery = ""
      }
    }
  }
  
  func selectMention(user: User) {
    if !taggedUsers.contains(where: { $0.userId == user.userId }) {
      taggedUsers.append(user)
    }
    self.showPicker = false
    self.mentionQuery = ""
  }

  // MARK: @All - 모든 팀원 태그
  func selectAllMembers(members: [User]) {
    // 기존에 없는 멤버만 추가
    for member in members {
      if !taggedUsers.contains(where: { $0.userId == member.userId }) {
        taggedUsers.append(member)
      }
    }
    self.showPicker = false
    self.mentionQuery = ""
  }

  // MARK: @ 이후 텍스트만 제거
  func removeMentionText(from content: String) -> String {
    guard let lastAtIndex = content.lastIndex(of: "@") else {
      return content
    }
    return String(content[..<lastAtIndex])
  }

  func dismissKeyboardAndClear() {
    self.mentionQuery = ""
    self.taggedUsers.removeAll() // 많이 태그 했다가 키보드 내려갔을때 다시 태그해야하는 불편함
    KeyboardHelper.dismiss()
  }
}
