//
//  InboxNotificationRow.swift
//  DanceMachine
//
//  Created by Paidion on 11/5/25.
//

import SwiftUI

struct InboxNotificationRow: View {
  let notification: InboxNotification
  
  
  var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: 8) {
        // 알림 유형
        VStack(alignment: .leading) {
          if notification.type == .feedback {
            Image(systemName: "ellipsis.message")
          } else {
            Image(systemName: "arrowshape.turn.up.left")
          }
          Spacer()
        }
        .foregroundStyle(.secondaryStrong)
        
        // 알림 전체 내용
        VStack(alignment: .leading, spacing: 12) {
          // 비디오 제목 + 날짜
          HStack(spacing: 0) {
            Text(notification.videoTitle)
              .font(.footnoteMedium)
              .foregroundStyle(.labelAssitive)
              .multilineTextAlignment(.leading)
            
            Spacer()
            
            Text(notification.date.listTimeLabel())
              .font(.footnoteMedium)
              .foregroundStyle(.labelAssitive)
              .multilineTextAlignment(.leading)
          }
          
          VStack(alignment: .leading, spacing: 8) {
            // 알림 제목
            HStack(spacing: 0) {
              Text(notification.senderName)
                .font(.heading1SemiBold)
                .foregroundStyle(.labelStrong)
                .multilineTextAlignment(.leading)
              Text(notification.type == .feedback ? String(localized: " 님이 피드백을 남겼어요") : String(localized: " 님이 답글을 남겼어요"))
                .font(.heading1Medium)
                .foregroundStyle(.labelNormal)
                .multilineTextAlignment(.leading)
            }
            
            // 알림 내용
            Text(notification.content)
              .font(.body1Medium)
              .foregroundStyle(.labelNormal)
              .multilineTextAlignment(.leading)
          }
        }
        
      }
      .contentShape(Rectangle())
      .padding(.horizontal, 16)
      .padding(.vertical, 20)
    }
    .background(notification.isRead ? .clear : .fillAlternative )

    Divider()
      .foregroundStyle(.strokeNormal)
  }
}

#Preview {
  InboxNotificationRow(
    notification: InboxNotification(
      notificationId: "",
      type: InboxNotificationType.feedback,
      videoId: "",
      videoURL: "",
      videoTitle: "dd",
      senderName: "조재훈",
      teamspace: Teamspace(
        teamspaceId: UUID(),
        ownerId: "",
        teamspaceName: ""
      ),
      content: "dddddddd",
      date: Date(),
      isRead: false
    )
  )
}
