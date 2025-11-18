//
//  ReplyRecycle.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/28/25.
//

import SwiftUI

struct ReplyRecycle: View {
  @State private var mM = MentionManager()
  
  let teamMembers: [User]
  let replyingTo: User?
  let onSubmit: (String, [String]) -> Void
  let refresh: () -> Void
  
  @State private var content: String = ""
  @State private var mentionQuery: String = ""
  
  
  private var filteredMembers: [User] {
    if mM.mentionQuery.isEmpty {
      return teamMembers
    }
    return teamMembers.filter {
      $0.name.lowercased().contains(mM.mentionQuery.lowercased())
    }
  }
  
  var body: some View {
    VStack(spacing: 16) {
      if replyingTo != nil {
        replyTo
      }
      if !mM.taggedUsers.isEmpty {
        TaggedUsersView(
          taggedUsers: mM.taggedUsers,
          teamMembers: teamMembers,
          onRemove: { userId in
            mM.taggedUsers.removeAll { $0.userId == userId }
          },
          onRemoveAll: { mM.taggedUsers.removeAll() }
        )
      }
      CustomTextField(
        content: $content,
        placeHolder: mM.taggedUsers.isEmpty ? "@팀원 태그" : "답글을 입력해주세요.",
        submitAction: {
          var taggedIds = Set(mM.taggedUsers.map { $0.userId })
          if let replyToId = replyingTo?.userId {
            taggedIds.insert(replyToId)
          }
          onSubmit(content, Array(taggedIds))
          self.content = ""
        },
        onFocusChange: {_ in },
        autoFocus: true
      )
      .onChange(of: content) { oldValue, newValue in
        mM.handleMention(oldValue: oldValue, newValue: newValue)
      }
    }
    .padding([.vertical, .horizontal], 16)
    .background(
      RoundedRectangle(cornerRadius: 20)
        .fill(Color.backgroundElevated)
    )
    .animation(.easeInOut(duration: 0.2), value: content.count)
    .overlay(alignment: .bottom) {
      if mM.showPicker {
        MentionPicker(
          filteredMembers: filteredMembers,
          action: {
            mM.selectMention(user: $0)
            self.content = mM.removeMentionText(from: self.content)
          },
          selectAll: {
            mM.selectAllMembers(members: filteredMembers)
            self.content = mM.removeMentionText(from: self.content)
          },
          taggedUsers: mM.taggedUsers
        )
        .padding(.bottom, 65)
      }
    }
  }
  
  private var replyTo: some View {
    HStack {
      Text("@\(replyingTo?.name ?? "알수 없는 유저")에게 답글 남기는중")
        .font(.footnoteMedium)
        .foregroundStyle(.labelNormal)
      Spacer()
      clearButton
    }
  }
  
  private var clearButton: some View {
    Button {
      refresh()
    } label: {
      Image(systemName: "xmark")
        .font(.system(size: 17))
        .foregroundStyle(.labelNormal)
    }
  }
}

#Preview {
  @Previewable @State var taggedUsers: [User] = .init(
    [User(
      userId: "1",
      email: "",
      name: "서영",
      loginType: LoginType.apple,
      fcmToken: "",
      termsAgreed: true,
      privacyAgreed: true
    ),
     User(
      userId: "2",
      email: "",
      name: "카단",
      loginType: LoginType.apple,
      fcmToken: "",
      termsAgreed: true,
      privacyAgreed: true
     ),
     User(
      userId: "3",
      email: "",
      name: "벨코",
      loginType: LoginType.apple,
      fcmToken: "",
      termsAgreed: true,
      privacyAgreed: true
     )]
  )
  ReplyRecycle(
    teamMembers: taggedUsers,
    replyingTo: User(
      userId: "",
      email: "",
      name: "22",
      loginType: LoginType.apple,
      fcmToken: "",
      termsAgreed: true,
      privacyAgreed: true
      
    ),
    onSubmit: {_, _ in
    },
    refresh: {}
  )
}
