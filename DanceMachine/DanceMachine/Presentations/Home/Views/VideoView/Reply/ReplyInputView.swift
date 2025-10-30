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
    VStack(spacing: 8) {
      replyTo
      taggedView
      CustomTextField(
        content: $content,
        placeHolder: "답글을 입력해주세요.",
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
      .animation(.easeInOut(duration: 0.2), value: mM.showPicker)
      .onChange(of: content) { oldValue, newValue in
        mM.handleMention(oldValue: oldValue, newValue: newValue)
      }
    }
    .padding(.vertical, 8)
    .padding(.horizontal, 16)
    .background(
      RoundedRectangle(cornerRadius: 20)
        .fill(Color.gray)
    )
    .overlay(alignment: .bottom) {
      if mM.showPicker {
        MentionPicker(
          filteredMembers: filteredMembers,
          action: {
            mM.selectMention(user: $0)
            self.content = ""
          },
          taggedUsers: mM.taggedUsers
        )
        .padding(.bottom, 60)
      }
    }
  }
  
  private var replyTo: some View {
    HStack {
      Text("@\(replyingTo?.name ?? "알수 없는 유저")에게 답글 남기는중")
        .font(.system(size: 14))
        .foregroundColor(.secondary)
      Spacer()
      clearButton
    }
  }
  
  private var clearButton: some View {
    Button {
      refresh()
    } label: {
      HStack { // FIXME: 아이콘 수정, 폰트 수정
        Image(systemName: "arrow.trianglehead.clockwise.rotate.90")
      }
      .foregroundStyle(.black) // FIXME: 컬러 수정
    }
  }
  // MARK: 태그된 사용자 표시
  private var taggedView: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 4) {
        ForEach(mM.taggedUsers, id: \.userId) { user in
          HStack(spacing: 0) {
            Text("@")
              .font(.system(size: 16)) // FIXME: 폰트 수정
              .foregroundStyle(.purple) // FIXME: 컬러 수정
            Text(user.name)
              .font(.system(size: 16)) // FIXME: 폰트 수정
              .foregroundStyle(.purple) // FIXME: 컬러 수정
            Button {
              mM.taggedUsers.removeAll { $0.userId == user.userId }
            } label: {
              Image(systemName: "xmark.circle.fill")
                .foregroundStyle(Color.red) // FIXME: 컬러 수정
            }
          }
          .animation(nil, value: mM.taggedUsers)
        }
      }
    }
  }
  // MARK: 멘션 피커
  private var mentionPicker: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("팀원 선택")
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(.white.opacity(0.7))
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)

      ScrollView {
        LazyVStack(alignment: .leading, spacing: 4) {
          ForEach(filteredMembers, id: \.userId) { user in
            Button {
              mM.selectMention(user: user)
              self.content = ""
            } label: {
              HStack(spacing: 8) {
                Image(systemName: "person.circle.fill")
                  .foregroundStyle(
                    mM.taggedUsers.contains(where: { $0.userId == user.userId })
                    ? .purple
                    : .gray
                  )

                Text(user.name)
                  .font(.system(size: 16))
                  .foregroundStyle(.white)

                Spacer()

                if mM.taggedUsers.contains(where: { $0.userId == user.userId }) {
                  Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.purple)
                }
              }
              .padding(.horizontal, 16)
              .padding(.vertical, 12)
              .background(
                mM.taggedUsers.contains(where: { $0.userId == user.userId })
                ? Color.purple.opacity(0.1)
                : Color.clear
              )
              .clipShape(RoundedRectangle(cornerRadius: 10))
              .contentShape(Rectangle())
            }
          }
        }
        .padding(.horizontal, 8)
      }
      .frame(maxHeight: 160)
    }
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.gray)
    )
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
