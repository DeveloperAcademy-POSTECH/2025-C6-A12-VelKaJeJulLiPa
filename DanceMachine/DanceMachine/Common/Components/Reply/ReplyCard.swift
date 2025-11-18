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
  let showCreateReportSheet: () -> Void
  
  @State private var showMenu: Bool = false
  
  var body: some View {
    HStack(alignment: .top, spacing: 8) {
      Image(systemName: "arrowshape.turn.up.right")
        .font(.system(size: 14))
        .rotationEffect(.degrees(180))
        .scaleEffect(x: -1, y: 1)
        .foregroundStyle(.labelNormal)
      VStack(alignment: .leading, spacing: 12) {
        topRow
        taggedUserRow
        replyButton
      }
      Spacer()
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 10)
    .padding(.horizontal, 25)
    .contentShape(Rectangle())
    .onLongPressGesture(perform: {
      showMenu.toggle()
    })
    .contextMenu {
      contextRow
    }
    .sensoryFeedback(.success, trigger: showMenu)
  }

  private var topRow: some View {
    HStack {
      Text(authorUser?.name ?? "알 수 없는 유저")
        .font(.footnoteSemiBold)
        .foregroundStyle(.labelNormal)
      if reply.createdAt != nil {
        Text("·")
          .font(.footnoteMedium)
          .foregroundStyle(.labelAssitive)
        Text(reply.createdAt?.listTimeLabel() ?? "방금 전")
          .font(.footnoteMedium)
          .foregroundStyle(.labelAssitive)
      }
      Spacer()
    }
    .overlay(alignment: .trailing) {
      Menu {
        contextRow
      } label: {
        Image(systemName: "ellipsis")
          .font(.system(size: 14))
          .foregroundStyle(.labelStrong)
          .frame(width: 22, height: 22)
      }
      .frame(width: 44, height: 44)
      .contentShape(Rectangle())
      .offset(x: 11)  // 터치 영역 확장으로 인한 오른쪽 offset
      .tint(Color.accentRedStrong)
    }
  }
  
  private var taggedUserRow: some View {
    Text(buildAttributedString())
      .font(.body1Medium)
      .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func buildAttributedString() -> AttributedString {
    var result = AttributedString()

    if !taggedUsers.isEmpty {
      for user in taggedUsers {
        var tag = AttributedString("@\(user.name) ")
        tag.foregroundColor = .accentBlueStrong
        result.append(tag)
      }
    }

    var content = AttributedString(reply.content)
    content.foregroundColor = .labelStrong
    result.append(content)

    return result
  }
  
  private var replyButton: some View {
    Button {
      replyAction()
    } label: {
      Text("답글달기")
        .font(.footnoteMedium)
        .foregroundStyle(.labelNormal)
    }
    .buttonStyle(.plain)
  }
  
  private var contextRow: some View {
    VStack(alignment: .leading, spacing: 16) {
      if reply.authorId == currentUserId {
        Button(role: .destructive) {
          onDelete()
        } label: {
          Label("삭제", systemImage: "trash")
        }
      } else {
        Button(role: .destructive) {
          showCreateReportSheet()
        } label: {
          Label("신고하기", systemImage: "light.beacon.max")
        }
      }
    }
  }
}

#Preview {
  ReplyCard(
    reply: Reply(
      replyId: "",
      feedbackId: "",
      authorId: "222",
      content: "안녕하세용안녕하세요안녕ddd",
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
    currentUserId: "222",
    onDelete: {},
    showCreateReportSheet: {}
  )
}
