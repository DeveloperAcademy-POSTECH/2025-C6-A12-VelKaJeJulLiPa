//
//  InboxViewModel.swift
//  DanceMachine
//
//  Created by Paidion on 10/23/25.
//

import Foundation
import Combine

import FirebaseFirestore


final class InboxViewModel: ObservableObject {
  @Published var notifications: [Notification] = []
  @Published var inboxNotifications: [InboxNotification] = []
  @Published var isLoading = false
  @Published var isRefreshing = false
  
  private var lastDocument: DocumentSnapshot? = nil
  private var canLoadMore = true
  
  /// 알림 목록 불러오는 메서드
  func loadNotifications(reset: Bool = false) async {
    guard !isLoading else { return }
    
    if reset {
      prepareForInitialLoad()
    } else if !canLoadMore {
      return
    }
    
    isLoading = true
    defer { isLoading = false }
    
    do {
      let userId = FirebaseAuthManager.shared.userInfo?.userId ?? ""
      let (fetched, lastDoc): ([Notification], DocumentSnapshot?) = try await FirestoreManager.shared.fetchNotificationList(
        userId: userId,
        lastDocument: reset ? nil : lastDocument
      )
      
      updateNotifications(with: fetched, reset: reset)
      lastDocument = lastDoc
      canLoadMore = fetched.count == 20
      
      try await appendInboxNotifications(from: fetched, reset: reset)
    } catch {
      print("❌ Failed to load notifications: \(error)")
    }
  }
  
  /// 새로고침
  func refresh() async {
    guard !isRefreshing else { return }
    isRefreshing = true
    defer { isRefreshing = false }
    await loadNotifications(reset: true)
  }
  
  
  /// 새로고침 관련 데이터 초기화
  private func prepareForInitialLoad() {
    lastDocument = nil
    canLoadMore = true
    notifications = []
  }
  
  /// 서버에서 받아온 Notification 정보를 notification 변수에 업데이트하는 메서드
  private func updateNotifications(with list: [Notification], reset: Bool) {
    if reset {
      notifications = list
    } else {
      notifications.append(contentsOf: list)
    }
  }
  
  /// notification 정보를  InboxNotification 변환하는 메서드
  /// notification 정보를 활용해서 비디오 제목, 알림 보내는 사람의 이름을 DB에서 가져오고, 알림을 보여주기 위한 정보를 세팅합니다.
  /// reset 상태(새로고침 여부)에 따라 분기처리합니다.
  /// - Parameters:
  ///  - notifications: DB의 notification 문서 정보
  ///  - reset: 새로고침 여부
  private func appendInboxNotifications(from notifications: [Notification], reset: Bool) async throws {
    let userId = FirebaseAuthManager.shared.userInfo?.userId ?? ""
    
    let transformed: [InboxNotification] = await withTaskGroup(of: Result<InboxNotification, Error>.self) { group in
      for notification in notifications {
        group.addTask {
          do {
            async let videoDoc = self.getVideoDoc(from: notification.videoId)
            async let senderDoc = self.getSenderDoc(from: notification.senderId)
            async let teamspaceDoc = self.getTeamspaceDoc(from: notification.teamspaceId)
            async let isRead = self.getNotificationReadState(
              userId: userId,
              notificationId: notification.notificationId.uuidString
            )
            
            let type = self.getInboxNotificationType(from: notification)
            
            let video = try await videoDoc
            let sender = try await senderDoc
            let readState = try await isRead
            let teamspace = try await teamspaceDoc
            
            let inbox = InboxNotification(
              notificationId: notification.notificationId.uuidString,
              type: type,
              videoId: notification.videoId,
              videoURL: video.videoURL,
              videoTitle: video.videoTitle,
              senderName: sender.name,
              teamspace: teamspace,
              content: notification.content,
              date: notification.createdAt,
              isRead: readState
            )
            
            return .success(inbox)
          } catch {
            print("⚠️ Failed to transform notification \(notification.notificationId): \(error)")
            
            // 아래의 경우에 notification 문서와 user_notification 문서를 삭제합니다.
            //  1.
            let userId = userId
            let notificationId = notification.notificationId.uuidString
            
            Task {
              do {
                try await FirestoreManager.shared.delete(collectionType: .notification, documentID: notificationId)
                try await NotificationManager.shared.deleteUserNotification(
                  userId: userId,
                  notificationId: notificationId
                )
                print("🧹 Deleted video related notification in both notification and user_notification document: \(notificationId)")
              } catch {
                print("❌ Failed to delete Deleted video related notification in both notification and user_notification document: \(error)")
              }
            }
            return .failure(error)
          }
        }
      }
      
      var results: [InboxNotification] = []
      for await result in group {
        switch result {
        case .success(let inbox):
          results.append(inbox)
        case .failure:
          continue
        }
      }
      return results
    }
    
    let sortedTransformed = transformed.sorted(by: { $0.date > $1.date })
    
    await MainActor.run {
      if reset {
        self.inboxNotifications = sortedTransformed
      } else {
        self.inboxNotifications.append(contentsOf: sortedTransformed)
      }
    }
  }
  
  
  private func getVideoDoc(from id: String) async throws -> Video {
    let videoDoc: Video = try await FirestoreManager.shared.get(id, from: .video)
    return videoDoc
  }
  
  
  private func getSenderDoc(from id: String) async throws -> User {
    let senderDoc: User = try await FirestoreManager.shared.get(id, from: .users)
    return senderDoc
  }
  
  
  /// 특정 유저의 user_notification 서브컬렉션에서 is_read 상태를 가져옵니다.
  private func getNotificationReadState(userId: String, notificationId: String) async throws -> Bool {
    do {
      let snapshot = try await Firestore.firestore()
        .collection(CollectionType.users.rawValue)
        .document(userId)
        .collection(CollectionType.userNotification.rawValue)
        .document(notificationId)
        .getDocument()
      
      if let data = snapshot.data(),
         let isRead = data[UserNotification.CodingKeys.isRead.rawValue] as? Bool {
        return isRead
      } else {
        return false // 문서가 없거나 필드가 없으면 읽지 않은 것으로 간주
      }
    } catch {
      print("❌ is_read 불러오기 실패:", error.localizedDescription)
      return false
    }
  }
  
  
  /// 알림 유형 판별 메서드
  nonisolated private func getInboxNotificationType(from notification: Notification) -> InboxNotificationType {
    return notification.replyId == nil ? .feedback : .reply
  }
  
  // 알림 읽음 처리
  func markAsRead(userId: String, notificationId: String) async throws {
    do {
      try await NotificationManager.shared.markNotificationAsRead(userId: userId, notificationId: notificationId)
    } catch {
      print("error: \(error.localizedDescription)")
    }
  }
}

// FIXME: - 코드 위치 변경
struct InboxNotification: Equatable {
  let notificationId: String
  let type: InboxNotificationType
  let videoId: String
  let videoURL: String
  let videoTitle: String
  let senderName: String
  let content: String
  let date: Date
  let isRead: Bool
}
