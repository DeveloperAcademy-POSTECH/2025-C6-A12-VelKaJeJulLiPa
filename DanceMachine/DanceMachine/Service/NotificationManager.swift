//
//  NotificationManager.swift
//  DanceMachine
//
//  Created by Paidion on 10/31/25.
//

import UIKit
import Combine
import UserNotifications

import FirebaseFirestore


/// 알림 개수를 관리 매니저
final class NotificationManager: ObservableObject {
  
  static let shared = NotificationManager()
  private init() {}
  
  @Published var unreadNotificationCount: Int = 0
  
  
  /// 앱 아이콘 뱃지 카운트를 업데이트 (권한 확인 포함)
  func updateAppBadgeCount(to count: Int) async throws {
    let center = UNUserNotificationCenter.current()
    let settings = await center.notificationSettings()
    
    guard settings.authorizationStatus == .authorized else {
      throw NotificationError.unauthorized
    }
    
    do {
      unreadNotificationCount = count
      print("✅ 수신함 뱃지 카운트가 \(count)로 설정됨")
      try await center.setBadgeCount(count)
      print("✅ 앱 뱃지 카운트가 \(count)로 설정됨")
    } catch {
      throw NotificationError.badgeUpdateFailed(underlying: error)
    }
  }
  
  
  /// 서버에서 안 읽은 알림 개수를 받아 앱 아이콘 뱃지와 동기화
  func refreshBadge(for userId: String) async throws {
    do {
      let count = try await FirestoreManager.shared.fetchUnreadNotificationCount(for: userId)
      try await updateAppBadgeCount(to: count)
      print("🔢 서버에서 받아온 뱃지 카운트 \(count) 적용 완료")
    } catch {
      throw NotificationError.fetchUnreadCountFailed(underlying: error)
    }
  }
  
  
  /// 특정 알림을 읽음 처리하고, 로컬 뱃지 카운트를 하나 줄임
  func markNotificationAsRead(userId: String, notificationId: String) async throws {
    do {
      // 1️⃣ Firestore의 user_notification 컬렉션에서 is_read 업데이트
      try await FirestoreManager.shared.updateFieldsInSubcollection(
        under: .users,
        parentId: userId,
        subCollection: .userNotification,
        documentId: notificationId,
        asDictionary: [UserNotification.CodingKeys.isRead.rawValue:  true]
      )
      
      print("📬 알림 \(notificationId) 읽음 처리 완료")
      // 2️⃣ 뱃지 카운트 갱신하기
      try await self.refreshBadge(for: userId)
    } catch {
      throw NotificationError.markAsReadFailed(underlying: error)
    }
  }
  
  /// 특정 사용자의 user_notification 서브 컬렉션 문서를 삭제하는 메서드
  func deleteUserNotification(userId: String, notificationId: String) async throws {
    do {
      try await FirestoreManager.shared.deleteFromSubcollection(
        under: .users,
        parentId: userId,
        subCollection: .userNotification,
        target: notificationId
      )
      print("📬 user_notification 에서 \(notificationId) 삭제 처리 완료")
    } catch {
      throw NotificationError.delelteNotificationFalied(underlying: error)
    }
  }
  
  
  /// 특정 유저의 내 읽지 않은 알림 개수를 가져오는 메서드
  func fetchUnreadNotificationCount(userId: String) async throws  {
    let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date.now)!
    let oneMonthAgoTimestamp = Timestamp(date: oneMonthAgo)
    
    do {
      let snapshot = try await Firestore.firestore()
        .collection(CollectionType.users.rawValue)
        .document(userId)
        .collection(CollectionType.userNotification.rawValue)
        .whereField(UserNotification.CodingKeys.createdAt.rawValue, isGreaterThanOrEqualTo: oneMonthAgoTimestamp)
        .whereField(UserNotification.CodingKeys.isRead.rawValue, isEqualTo: false)
        .getDocuments()
      
      try await updateAppBadgeCount(to: snapshot.documents.count)
    } catch {
      throw NotificationError.fetchUnreadCountFailed(underlying: error)
    }
  }
  
  
}
