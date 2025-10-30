//
//  ReplyCard.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/28/25.
//

import SwiftUI

struct ReplyCard: View {
  let reply: Reply
  let authorUser: User?
  let taggedUsers: [User]
  let replyAction: () -> Void
  
  let currentUserId: String
  let onDelete: () -> Void
  
  var body: some View {
    HStack(alignment: .top, spacing: 16) {
      Image(systemName: "arrow.turn.down.right") // FIXME: 아이콘 수정
      VStack(alignment: .leading, spacing: 8) {
        topRow
        taggedUserRow
        replyButton
      }
      Spacer()
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 10)
    .background(Color.red.opacity(0.3))
    .padding(.horizontal, 16)
    .overlay(alignment: .topTrailing) {
      if reply.authorId == currentUserId {
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
  
  private var topRow: some View {
    HStack {
      Text(authorUser?.name ?? "알 수 없는 유저")
        .font(.system(size: 14)) // FIXME: 폰트수정
      if reply.createdAt != nil {
        Text("·")
          .font(.system(size: 14)) // FIXME: 폰트수정
        Text(reply.createdAt?.listTimeLabel() ?? "방금 전")
          .font(.system(size: 14)) // FIXME: 폰트수정
      }
      Spacer()
    }
  }
  
  private var taggedUserRow: some View {
    HStack {
      if !taggedUsers.isEmpty {
        ForEach(taggedUsers, id: \.userId) { user in
          Text("@\(user.name)")
            .font(.system(size: 16)) // FIXME: 폰트수정
        }
      }
      Text(reply.content)
        .font(.system(size: 16)) // FIXME: 폰트 수정
    }
  }
  
  private var replyButton: some View {
    Button {
      replyAction()
    } label: {
      Text("답글달기")
        .font(.caption)
        .foregroundStyle(.gray)
    }
  }
}

#Preview {
  ReplyCard(
    reply: Reply(
      replyId: "",
      feedbackId: "",
      authorId: "222",
      content: "ㅇㅋㅇㅋ",
      taggedUserIds: ["dddd"]
    ),
    authorUser: User(
      userId: "",
      email: "",
      name: "dd",
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
      )
    ],
    replyAction: {
    },
    currentUserId: "",
    onDelete: {}
  )
}
