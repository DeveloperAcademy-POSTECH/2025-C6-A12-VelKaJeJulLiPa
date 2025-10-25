//
//  FeedbackListView.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/25/25.
//

import SwiftUI

struct FeedbackCard: View {
  let feedback: Feedback
  let taggedUsers: [User]
  let replyCount: Int
  let action: () -> Void
  
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
//    .background(Color.gray.opacity(0.5))
    .glassEffect(.clear.tint(Color.gray), in: RoundedRectangle(cornerRadius: 10))
    .contentShape(Rectangle())
    .onTapGesture {
      action()
    }
  }
  
  private var authorName: some View {
    HStack {
      Text(feedback.authorId)
        .font(.system(size: 14)) // FIXME: 폰트 수정
      Text("·")
        .font(.system(size: 14)) // FIXME: 폰트 수정
      if feedback.createdAt != nil {
        Text(
          feedback.createdAt?.listTimeLabel() ?? ""
        )
        .font(.system(size: 14)) // FIXME: 폰트 수정
      }
    }
  }
  
  private var timeStamp: some View {
    HStack {
      Image(systemName: "clock") // FIXME: 이미지 수정
      if let endTime = feedback.endTime {
        Text("\(feedback.startTime?.formattedTime() ?? "00:00") ~ \(endTime.formattedTime())")
          .font(.system(size: 16)) // FIXME: 폰트 수정
      } else {
        Text(feedback.startTime?.formattedTime() ?? "00:00")
          .font(.system(size: 16)) // FIXME: 폰트 수정
      }
      
      Spacer()
      
      if !taggedUsers.isEmpty {
        HStack {
          ForEach(taggedUsers.prefix(2), id: \.userId) { user in
            Text("@\(user.name)")
              .font(.system(size: 16)) // FIXME: 폰트 수정
          }
          if taggedUsers.count > 2 {
            Text("+\(taggedUsers.count - 2)")
              .font(.system(size: 16)) // FIXME: 폰트 수정
          }
          Spacer()
        }
      }
    }
  }
  
  private var content: some View {
    Text(feedback.content)
      .font(.system(size: 16)) // FIXME: 폰트 수정
      .lineLimit(3) // FIXME: 수정
      .frame(maxWidth: .infinity, alignment: .leading)
  }
  
  private var replyButton: some View {
    Button {
      // TODO: 댓글 화면 이동
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
      createdAt: Date().addingTimeInterval(-60 * 0.5)
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
    action: {}
  )
}
