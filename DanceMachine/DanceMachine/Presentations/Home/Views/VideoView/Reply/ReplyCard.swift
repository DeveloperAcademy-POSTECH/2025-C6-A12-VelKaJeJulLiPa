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
    .onTapGesture {
      replyAction()
    }
    .onLongPressGesture(perform: {
      showMenu.toggle()
    })
    .contextMenu {
      contextRow
    }
    .sensoryFeedback(.success, trigger: showMenu)
  }
  
  private var topRow: some View {
    ZStack(alignment: .topTrailing) {
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
      Menu {
        contextRow
      } label: {
        Image(systemName: "ellipsis")
          .font(.system(size: 14))
          .foregroundStyle(.labelStrong)
      }
      .frame(width: 22, height: 22)
      .contentShape(Rectangle())
      .tint(Color.accentRedStrong)
    }
  }
  
  private var taggedUserRow: some View {
    HStack {
      if !taggedUsers.isEmpty {
        ForEach(taggedUsers, id: \.userId) { user in
          Text("@\(user.name)")
            .font(.body1Medium)
            .foregroundStyle(.accentBlueStrong)
        }
      }
      Text(reply.content)
        .font(.body1Medium)
        .foregroundStyle(.labelStrong)
    }
  }
  
  private var replyButton: some View {
    Button {
      replyAction()
    } label: {
      Text("답글달기")
        .font(.footnoteMedium)
        .foregroundStyle(.labelNormal)
    }
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
    currentUserId: "222",
    onDelete: {},
    showCreateReportSheet: {}
  )
}
