//
//  NotificationError.swift
//  DanceMachine
//
//  Created by Paidion on 10/31/25.
//

import Foundation


enum NotificationError: LocalizedError {
  case unauthorized
  case badgeUpdateFailed(underlying: Error)
  case fetchUnreadCountFailed(underlying: Error)
  case markAsReadFailed(underlying: Error)
  case delelteNotificationFalied(underlying: Error)
  
  var errorDescription: String? {
    switch self {
    case .unauthorized:
      return "알림 권한이 없습니다. 설정에서 알림을 허용해 주세요."
    case .badgeUpdateFailed(let underlying):
      return "앱 뱃지 업데이트에 실패했습니다. (\(underlying.localizedDescription))"
    case .fetchUnreadCountFailed(let underlying):
      return "서버에서 안 읽은 알림 개수를 가져오지 못했습니다. (\(underlying.localizedDescription))"
    case .markAsReadFailed(let underlying):
      return "알림 읽음 처리 과정에서 에러가 발생했습니다. (\(underlying.localizedDescription))"
    case .delelteNotificationFalied(let underlying):
      return "삭제된 영상이나 팀스페이스로 관련 정보(알림 문서, 사용자 알림 서브컬렉션) 삭제에 실패했습니다. (\(underlying.localizedDescription))"
    }
  }
}
