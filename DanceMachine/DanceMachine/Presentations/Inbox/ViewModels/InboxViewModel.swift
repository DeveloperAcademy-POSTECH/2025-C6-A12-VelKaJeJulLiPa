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
  
  // MARK: - Public Methods
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
      try await NotificationManager.shared.refreshBadge(for: userId)
    } catch {
      print("❌ Failed to load notifications: \(error)")
    }
  }
  
  func refresh() async {
    guard !isRefreshing else { return }
    isRefreshing = true
    defer { isRefreshing = false }
    await loadNotifications(reset: true)
  }
  
  
  // MARK: - Private: Notification Transform
  
  private enum InboxResult {
    case success(InboxNotification)
    case failure(String) // notificationId
  }
  
  /// notification 정보를 InboxNotification으로 병렬로 변환하는 메서드
  private func appendInboxNotifications(from notifications: [Notification], reset: Bool) async throws {
    let userId = FirebaseAuthManager.shared.userInfo?.userId ?? ""
    
    let transformed: [InboxNotification] = await withTaskGroup(of: InboxResult.self) { group in
      for notification in notifications {
        group.addTask {
          await self.transformNotificationToInbox(notification: notification, userId: userId)
        }
      }
      
      var results: [InboxNotification] = []
      
      for await result in group {
        switch result {
        case .success(let inbox):
          results.append(inbox)
          
        case .failure(let notificationId):
          await self.handleInvalidNotification(notificationId: notificationId, userId: userId)
        }
      }
      return results
    }
    
    let sorted = transformed.sorted(by: { $0.date > $1.date })
    
    await MainActor.run {
      if reset {
        self.inboxNotifications = sorted
      } else {
        self.inboxNotifications.append(contentsOf: sorted)
      }
    }
  }
  
  /// 하나의 Notification을 InboxNotification 변환하는 메서드
  private func transformNotificationToInbox(notification: Notification, userId: String) async -> InboxResult {
    do {
      async let videoDoc = getVideoDoc(from: notification.videoId)
      async let senderDoc = getSenderDoc(from: notification.senderId)
      async let teamspaceDoc = getTeamspaceDoc(from: notification.teamspaceId)
      async let readState = getNotificationReadState(
        userId: userId,
        notificationId: notification.notificationId.uuidString
      )
      
      let notificationType = getInboxNotificationType(from: notification)
      
      let video = try await videoDoc
      let sender = try await senderDoc
      let teamspace = try await teamspaceDoc
      let isRead = try await readState
      
      let inbox = InboxNotification(
        notificationId: notification.notificationId.uuidString,
        type: notificationType,
        videoId: notification.videoId,
        videoURL: video.videoURL,
        videoTitle: video.videoTitle,
        senderName: sender.name,
        teamspace: teamspace,
        content: notification.content,
        date: notification.createdAt,
        isRead: isRead
      )
      
      return .success(inbox)
      
    } catch {
      print("⚠️ Error transforming notification into inboxNotification: \(notification.notificationId.uuidString) / error: \(error)")
      return .failure(notification.notificationId.uuidString)
    }
  }
  
  
  /// 삭제된 영상에 대한 notification 문서 삭제 및  user_notification 문서 삭제
  /// BatchManager 를 사용해 두 문서를 모두 삭제 (모두 성공하거나 모두 실패)
  private func handleInvalidNotification(notificationId: String, userId: String) async {
    let db = Firestore.firestore()
    
    let notificationRef = db.collection(CollectionType.notification.rawValue).document(notificationId)
    let userNotificationRef = db.collection(CollectionType.users.rawValue)
      .document(userId)
      .collection(CollectionType.userNotification.rawValue)
      .document(notificationId)
    
    do {
      try await BatchManager.shared.perform { batch in
        batch.deleteDocument(notificationRef)
        batch.deleteDocument(userNotificationRef)
      }
      print("🧹 Batch cleanup completed for invalid notification: \(notificationId)")
    } catch {
      print("❌ Failed batch cleanup: \(notificationId), error: \(error)")
    }
  }

  
  private func getVideoDoc(from id: String) async throws -> Video {
    try await FirestoreManager.shared.get(id, from: .video)
  }
  
  private func getSenderDoc(from id: String) async throws -> User {
    try await FirestoreManager.shared.get(id, from: .users)
  }
  
  private func getTeamspaceDoc(from id: String) async throws -> Teamspace {
    try await FirestoreManager.shared.get(id, from: .teamspace)
  }
  
  nonisolated private func getInboxNotificationType(from notification: Notification) -> InboxNotificationType {
    return notification.replyId == nil ? .feedback : .reply
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
        return false
      }
    } catch {
      print("❌ is_read 불러오기 실패:", error.localizedDescription)
      return false
    }
  }
  
  
  // MARK: - Notification Read State
  
  func markAsRead(userId: String, notificationId: String) async throws {
    do {
      try await NotificationManager.shared.markNotificationAsRead(userId: userId, notificationId: notificationId)
    } catch {
      print("error: \(error.localizedDescription)")
    }
  }
  
  
  // MARK: - Helpers: Pagination & State
  
  private func prepareForInitialLoad() {
    lastDocument = nil
    canLoadMore = true
    notifications = []
  }
  
  private func updateNotifications(with list: [Notification], reset: Bool) {
    if reset {
      notifications = list
    } else {
      notifications.append(contentsOf: list)
    }
  }
}


// MARK: - InboxNotification

struct InboxNotification: Equatable {
  let notificationId: String
  let type: InboxNotificationType
  let videoId: String
  let videoURL: String
  let videoTitle: String
  let senderName: String
  let teamspace: Teamspace
  let content: String
  let date: Date
  let isRead: Bool
}
