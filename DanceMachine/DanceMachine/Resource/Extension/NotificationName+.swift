//
//  Notification+.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/19/25.
//

import Foundation

extension Foundation.Notification.Name {
  static let sectionDidUpdate = Foundation.Notification.Name("sectionDidUpdate")
  static let showVideoPicker = Foundation.Notification.Name("showVideoPicker")
  static let videoUpload = Foundation.Notification.Name("videoUpload")
  static let didReceiveDeeplink = Foundation.Notification.Name("didReceiveDeeplink")
  static let needToMarkAsRead = Foundation.Notification.Name("needToMarkAsRead")
  
  static let showEditToast = Foundation.Notification.Name("showEditToast")
  static let showDeleteToast = Foundation.Notification.Name("showDeleteToast")
  static let showEditWarningToast = Foundation.Notification.Name("showEditWarningToast")
  static let showEditVideoTitleToast = Foundation.Notification.Name("showEditVideoTitleToast")
}

enum NotificationEvent {
  case sectionDidUpdate
  case showVideoPicker
  case videoUpload
  case didReceiveDeeplink
  case needToMarkAsRead
  case showEditToast
  case showDeleteToast
  case showEditWarningToast
  case showEditVideoTitleToast
  
  var name: Foundation.Notification.Name {
    switch self {
    case .sectionDidUpdate: .sectionDidUpdate
    case .showVideoPicker: .showVideoPicker
    case .videoUpload: .videoUpload
    case .didReceiveDeeplink: .didReceiveDeeplink
    case .needToMarkAsRead: .needToMarkAsRead
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



