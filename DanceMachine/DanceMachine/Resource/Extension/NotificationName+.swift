//
//  Notification+.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/19/25.
//

import Foundation

extension Foundation.Notification.Name {
  // 섹션 업데이트 후 자동 서버 호출
  static let sectionDidUpdate = Foundation.Notification.Name("sectionDidUpdate")
  // 비디오 업로드 후 자동 서버 호출
  static let videoUpload = Foundation.Notification.Name("videoUpload")
  static let didReceiveDeeplink = Foundation.Notification.Name("didReceiveDeeplink")
  static let needToMarkAsRead = Foundation.Notification.Name("needToMarkAsRead")
  // rootView에 탭바에서 관리하는 액션 버튼(프로젝트 생성 노티)
  static let showCreateProject = Foundation.Notification.Name("showCreateProject")
  // rootView에 탭바에서 관리하는 액션 버튼(곡 생성 노티)
  static let showCreateTrack = Foundation.Notification.Name("showCreateTrack")
  // rootView에 탭바에서 관리하는 액션 버튼(리스트가 열렸는지)
  static let projectDidExpand = Foundation.Notification.Name("projectDidExpand")
  // rootView에 탭바에서 관리하는 액션 버튼(리스트가 닫혔는지)
  static let projectDidCollapse = Foundation.Notification.Name("projectDidCollapse")
}

enum NotificationEvent {
  case sectionDidUpdate
  case videoUpload
  case didReceiveDeeplink
  case needToMarkAsRead
  case showCreateProject
  case showCreateTrack
  case projectDidExpand
  case projectDidCollapse

  var name: Foundation.Notification.Name {
    switch self {
    case .sectionDidUpdate: .sectionDidUpdate
    case .videoUpload: .videoUpload
    case .didReceiveDeeplink: .didReceiveDeeplink
    case .needToMarkAsRead: .needToMarkAsRead
    case .showCreateProject: .showCreateProject
    case .showCreateTrack: .showCreateTrack
    case .projectDidExpand: .projectDidExpand
    case .projectDidCollapse: .projectDidCollapse
    }
  }
}

extension NotificationCenter {
  static func post(_ event: NotificationEvent, object: Any? = nil) {
    NotificationCenter.default.post(name: event.name, object: object)
  }
}



