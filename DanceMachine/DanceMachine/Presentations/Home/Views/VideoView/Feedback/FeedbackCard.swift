//
//  FeedbackListView.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/25/25.
//

import SwiftUI

struct FeedbackCard: View {
  let feedback: Feedback
  let authorUser: User?
  let taggedUsers: [User]
  let replyCount: Int
  let action: () -> Void
  let showReplySheet: () -> Void
  
  let currentTime: Double
  let startTime: Double?
  let timeSeek: () -> Void
  
  let currentUserId: String
  let onDelete: () -> Void
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      authorName
      Spacer().frame(height: 4)
      timeStamp
      content
      replyButton
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 16)
    .background(
      Color.gray.opacity(0.3)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    )
//    .glassEffect(.clear.tint(Color.gray), in: RoundedRectangle(cornerRadius: 10))
    .contentShape(Rectangle())
    .onTapGesture {
      action()
    }
    .overlay(alignment: .topTrailing) {
      if feedback.authorId == currentUserId {
        Menu { // FIXME: 아이콘 컬러 수정
          Button(role: .destructive) {
            onDelete()
          } label: {
            Label("삭제", systemImage: "trash")
          }
        } label: {
          Image(systemName: "ellipsis")
            .foregroundStyle(.gray)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .tint(.gray.opacity(0.8))
      }
    }
  }
  
  private var authorName: some View {
    HStack {
      Text(authorUser?.name ?? "알 수 없는 사용자")
        .font(.system(size: 14)) // FIXME: 폰트 수정
        .foregroundStyle(Color.black)
      Text("·")
        .font(.system(size: 14)) // FIXME: 폰트 수정
        .foregroundStyle(Color.black)
      if feedback.createdAt != nil {
        Text(
          feedback.createdAt?.listTimeLabel() ?? ""
        )
        .font(.system(size: 14)) // FIXME: 폰트 수정
        .foregroundStyle(Color.black)
      }
      Spacer()
    }
  }
  
  private var timeStamp: some View {
    HStack {
      if let endTime = feedback.endTime {
        TimestampButton(
          text: "\(feedback.startTime?.formattedTime() ?? "00:00") ~ \(endTime.formattedTime())",
          timeSeek: { timeSeek() }
        )
      } else {
        TimestampButton(
          text: "\(feedback.startTime?.formattedTime() ?? "00:00")",
          timeSeek: { timeSeek() }
        )
      }
      
      if !taggedUsers.isEmpty {
        Menu {
          ForEach(taggedUsers, id: \.userId) { user in
            Text(user.name)
          }
        } label: {
          HStack {
            ForEach(taggedUsers.prefix(4), id: \.userId) { user in
              Text("@\(user.name)")
                .font(.system(size: 16)) // FIXME: 폰트 수정
                .foregroundStyle(.blue) // FIXME: 폰트 수정
            }
            if taggedUsers.count > 4 {
              Text("...")
                .font(.system(size: 16)) // FIXME: 폰트 수정
                .foregroundStyle(.blue) // FIXME: 폰트 수정
            }
          }
        }
        .tint(.gray.opacity(0.8))
      }
      Spacer()
    }
  }
  
  private var content: some View {
    Text(feedback.content)
      .font(.system(size: 16)) // FIXME: 폰트 수정
      .foregroundStyle(Color.black) // FIXME: 컬러 수정
      .lineLimit(3) // FIXME: 수정
      .frame(maxWidth: .infinity, alignment: .leading)
  }
  
  private var replyButton: some View {
    Button {
      showReplySheet()
    } label: {
      HStack(spacing: 4) {
        Image(systemName: "message")
          .font(.system(size: 16)) // FIXME: 폰트 수정 // FIXME: 이미지 수정
        Text("\(replyCount)")
          .font(.system(size: 16)) // FIXME: 폰트 수정
      }
    }
    .frame(maxWidth: .infinity, alignment: .trailing)
  }
}

#Preview {
  FeedbackCard(
    feedback: Feedback(
      feedbackId: UUID(),
      videoId: "",
      authorId: "dddd",
      content: "야이 놈아.야이 놈아.야이 놈아.야이 놈아.야이 놈아.야이 놈아.야이 놈아.야이 놈아.야이 놈아.야이 놈아.야이 놈아.야이 놈아,야이 놈아,야이 놈아,야이 놈아,야이 놈아,야이 놈아",
      startTime: 1.44141414,
      endTime: 1.55555,
      createdAt: Date().addingTimeInterval(-60 * 0.5),
      teamspaceId: "",
    ),
    authorUser: User(
      userId: "1",
      email: "",
      name: "재훈",
      loginType: LoginType.apple,
      fcmToken: "",
      termsAgreed: true,
      privacyAgreed: true,
    ),
    taggedUsers: [
      User(
        userId: "ddd",
        email: "",
        name: "dddd",
        loginType: LoginType.apple,
        fcmToken: "",
        termsAgreed: true,
        privacyAgreed: true
      ),
      User(
        userId: "ddd",
        email: "",
        name: "dddd",
        loginType: LoginType.apple,
        fcmToken: "",
        termsAgreed: true,
        privacyAgreed: true
      ),
      User(
        userId: "ddd",
        email: "",
        name: "dddd",
        loginType: LoginType.apple,
        fcmToken: "",
        termsAgreed: true,
        privacyAgreed: true
      )
    ],
    replyCount: 20,
    action: {
    },
    showReplySheet: {},
    currentTime: 30.0,
    startTime: 50.0,
    timeSeek: {},
    currentUserId: "",
    onDelete: {}
  )
}
