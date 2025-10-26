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
}

enum NotificationEvent {
  case sectionDidUpdate
  case showVideoPicker
  case videoUpload
  
  var name: Foundation.Notification.Name {
    switch self {
    case .sectionDidUpdate: .sectionDidUpdate
    case .showVideoPicker: .showVideoPicker
    case .videoUpload: .videoUpload
    }
  }
}

extension NotificationCenter {
  static func post(_ event: NotificationEvent, object: Any? = nil) {
    NotificationCenter.default.post(name: event.name, object: object)
  }
}



