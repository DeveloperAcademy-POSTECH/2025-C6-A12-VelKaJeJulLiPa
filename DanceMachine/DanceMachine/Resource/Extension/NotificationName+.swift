//
//  Notification+.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/19/25.
//

import Foundation

extension Foundation.Notification.Name {
  // 비디오 업로드 후 자동 서버 호출
  static let videoUpload = Foundation.Notification.Name("videoUpload")
  static let didReceiveDeeplink = Foundation.Notification.Name("didReceiveDeeplink")
  static let needToMarkAsRead = Foundation.Notification.Name("needToMarkAsRead")
  static let projectDidCollapse = Foundation.Notification.Name("projectDidCollapse")
  // 영상 이동 토스트
  static let showEditToast = Foundation.Notification.Name("showEditToast")
  // 영상 삭제 토스트
  static let showDeleteToast = Foundation.Notification.Name("showDeleteToast")
  // 섹션 글자 제한 토스트
  static let showEditWarningToast = Foundation.Notification.Name("showEditWarningToast")
  // 영상 이름 수정 제한 토스트
  static let showEditVideoTitleToast = Foundation.Notification.Name("showEditVideoTitleToast")
}

enum NotificationEvent {
  case videoUpload
  case didReceiveDeeplink
  case needToMarkAsRead
  case projectDidCollapse
  case showEditToast
  case showDeleteToast
  case showEditWarningToast
  case showEditVideoTitleToast
  
  var name: Foundation.Notification.Name {
    switch self {
    case .videoUpload: .videoUpload
    case .didReceiveDeeplink: .didReceiveDeeplink
    case .needToMarkAsRead: .needToMarkAsRead
    case .projectDidCollapse: .projectDidCollapse
    case .showEditToast: .showEditToast
    case .showDeleteToast: .showDeleteToast
    case .showEditWarningToast: .showEditWarningToast
    case .showEditVideoTitleToast: .showEditVideoTitleToast
    }
  }
}

extension NotificationCenter {
  static func post(_ event: NotificationEvent, object: Any? = nil) {
    NotificationCenter.default.post(name: event.name, object: object)
  }
}



