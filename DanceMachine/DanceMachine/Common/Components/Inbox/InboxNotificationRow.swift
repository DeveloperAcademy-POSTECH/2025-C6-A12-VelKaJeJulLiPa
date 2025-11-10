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
              Text(koreanParticle(notification.senderName) + " ")
                .font(.heading1Medium)
                .foregroundStyle(.labelNormal)
                .multilineTextAlignment(.leading)
              Text(notification.type == .feedback ? "피드백을 남겼어요" : "답글을 남겼어요" )
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
      .padding(.vertical, 24)
    }
    .background(notification.isRead ? .clear : .fillAlternative )

    Divider()
      .foregroundStyle(.strokeNormal)
  }
  
}
