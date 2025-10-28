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
            let userId = FirebaseAuthManager.shared.userInfo?.userId ?? "lUqpEVMVOIOJ3bO8gI63PX8Y62J2"// FIXME: 태스트할 때는 "lUqpEVMVOIOJ3bO8gI63PX8Y62J2" (파이디온 계정)
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
        let transformed: [InboxNotification] = try await withThrowingTaskGroup(of: InboxNotification.self) { group in
            for notification in notifications {
                group.addTask {
                    async let videoTitle = self.getVideoTitle(from: notification.videoId)
                    async let senderName = self.getSenderName(from: notification.senderId)
                    let type = self.getInboxNotificationType(from: notification)
                    
                    return InboxNotification(
                        notificationId: notification.notificationId.uuidString,
                        type: type,
                        videoTitle: try await videoTitle,
                        senderName: try await senderName,
                        content: notification.content,
                        date: notification.createdAt
                    )
                }
            }
            
            var results: [InboxNotification] = []
            for try await inbox in group {
                results.append(inbox)
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

    private func getVideoTitle(from id: String) async throws -> String {
        let videoDoc: Video = try await FirestoreManager.shared.get(id, from: .video)
        return videoDoc.videoTitle
    }

    private func getSenderName(from id: String) async throws -> String {
        let senderDoc: User = try await FirestoreManager.shared.get(id, from: .users)
        return senderDoc.name
    }

    /// 알림 유형 판별 메서드
    nonisolated private func getInboxNotificationType(from notification: Notification) -> InboxNotificationType {
        return notification.replyId == nil ? .feedback : .reply
    }
}

// FIXME: - 코드 위치 변경
struct InboxNotification: Equatable {
    let notificationId: String
    let type: InboxNotificationType
    let videoTitle: String
    let senderName: String
    let content: String
    let date: Date
}
