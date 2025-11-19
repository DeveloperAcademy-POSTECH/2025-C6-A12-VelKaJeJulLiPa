//
//  Notification+.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/19/25.
//

import Foundation

// MARK: - NotificationEvent (타입 안전한 Notification 관리)

enum NotificationEvent {
  // MARK: Video 관련
  case video(VideoEvent)

  // MARK: Section 관련
  case section(SectionEvent)

  // MARK: Toast 관련
  case toast(ToastEvent)

  // MARK: System 관련
  case system(SystemEvent)

  var name: Foundation.Notification.Name {
    switch self {
    case .video(let event): event.name
    case .section(let event): event.name
    case .toast(let event): event.name
    case .system(let event): event.name
    }
  }
}

// MARK: - Video Events

enum VideoEvent {
  case videoEdit // 영상 이동
  case videoDelete // 영상 삭제 완료
  case videoTitleEdit // 비디오 제목 업데이트 완료
  
  case videoEditFailed // 영상 이동 실패
  
  case refreshView

  var name: Foundation.Notification.Name {
    switch self {
    case .videoEdit: Foundation.Notification.Name("showEditToast")
    case .videoDelete: Foundation.Notification.Name("showDeleteToast")
    case .videoTitleEdit: Foundation.Notification.Name("showEditVideoTitleToast")
    case .videoEditFailed: Foundation.Notification.Name("videoEditFailed")
  
    case .refreshView: Foundation.Notification.Name("refreshVideoView")
    }
  }
}

// MARK: - Section Events

enum SectionEvent {
  case sectionCRUDFailed // 섹션 CRUD 토스트 (에러타입에 의해 분기)
  
  case sectionEditWarning // 섹션 이름 제한 토스트

  var name: Foundation.Notification.Name {
    switch self {
    case .sectionCRUDFailed: Foundation.Notification.Name("sectionCRUDFailed")
    case .sectionEditWarning: Foundation.Notification.Name("showEditWarningToast")
    }
  }
}

// MARK: - Toast Events

enum ToastEvent {
  case reportSuccess

  var name: Foundation.Notification.Name {
    switch self {
    case .reportSuccess: Foundation.Notification.Name("showCreateReportSuccessToast")
    }
  }
}

// MARK: - System Events

enum SystemEvent {
  case deeplink
  case markAsRead
  case projectCollapse

  var name: Foundation.Notification.Name {
    switch self {
    case .deeplink: Foundation.Notification.Name("didReceiveDeeplink")
    case .markAsRead: Foundation.Notification.Name("needToMarkAsRead")
    case .projectCollapse: Foundation.Notification.Name("projectDidCollapse")
    }
  }
}

// MARK: - NotificationCenter Extension

extension NotificationCenter {
  /// 타입 안전한 notification post
  static func post(_ event: NotificationEvent, object: Any? = nil, userInfo: [AnyHashable: Any]? = nil) {
    NotificationCenter.default.post(
      name: event.name,
      object: object,
      userInfo: userInfo
    )
  }

  /// 타입 안전한 notification publisher (SwiftUI용)
  static func publisher(for event: NotificationEvent, object: AnyObject? = nil) -> NotificationCenter.Publisher {
    NotificationCenter.default.publisher(for: event.name, object: object)
  }
}
