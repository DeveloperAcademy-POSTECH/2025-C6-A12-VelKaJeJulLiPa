//
//  ReplySheetInputView.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/16/25.
//

import SwiftUI

struct ReplySheetInputView: View {
  @Binding var content: String
  @Binding var isKeyboardVisible: Bool

  let taggedUsers: [User]
  let teamMembers: [User]
  let filteredMembers: [User]
  let showMentionPicker: Bool
  let placeholder: String

  let onSubmit: () -> Void
  let onContentChange: (String, String) -> Void
  let onSelectMention: (User) -> Void
  let onSelectAllMentions: () -> Void
  let onRemoveTag: (String) -> Void
  let onRemoveAllTags: () -> Void
  let onFocusChange: (Bool) -> Void

  @State private var viewHeight: CGFloat = 0

  var body: some View {
    VStack(spacing: 8) {
      // Tagged users
      if !taggedUsers.isEmpty {
        TaggedUsersView(
          taggedUsers: taggedUsers,
          teamMembers: teamMembers,
          onRemove: onRemoveTag,
          onRemoveAll: onRemoveAllTags
        )
      }

      // Text field
      CustomTextField(
        content: $content,
        placeHolder: placeholder,
        submitAction: onSubmit,
        onFocusChange: onFocusChange,
        autoFocus: false
      )
      .onChange(of: content, onContentChange)
    }
    .padding([.vertical, .horizontal], 16)
    .background(
      GeometryReader { geometry in
        Color.clear.onAppear {
          viewHeight = geometry.size.height
        }
        .onChange(of: geometry.size.height) { _, newHeight in
          viewHeight = newHeight
        }
      }
    )
    .background {
      if isKeyboardVisible {
        RoundedRectangle(cornerRadius: 20)
          .fill(Color.backgroundElevated)
      } else {
        Color.fillNormal
          .ignoresSafeArea()
          .overlay(alignment: .top) {
            Rectangle().frame(height: 1)
              .foregroundStyle(.fillAssitive)
          }
      }
    }
    .overlay(alignment: .bottom) {
      if showMentionPicker {
        MentionPicker(
          filteredMembers: filteredMembers,
          action: onSelectMention,
          selectAll: onSelectAllMentions,
          taggedUsers: taggedUsers
        )
        .padding(.bottom, viewHeight + 5)
      }
    }
  }
}

#Preview {
  ReplySheetInputView(
    content: .constant("답글 내용 테스트"),
    isKeyboardVisible: .constant(true),
    taggedUsers: [
      User(
        userId: "1",
        email: "test1@test.com",
        name: "김철수",
        loginType: .apple,
        fcmToken: "",
        termsAgreed: true,
        privacyAgreed: true
      ),
      User(
        userId: "2",
        email: "test2@test.com",
        name: "이영희",
        loginType: .apple,
        fcmToken: "",
        termsAgreed: true,
        privacyAgreed: true
      )
    ],
    teamMembers: [
      User(
        userId: "1",
        email: "test1@test.com",
        name: "김철수",
        loginType: .apple,
        fcmToken: "",
        termsAgreed: true,
        privacyAgreed: true
      ),
      User(
        userId: "2",
        email: "test2@test.com",
        name: "이영희",
        loginType: .apple,
        fcmToken: "",
        termsAgreed: true,
        privacyAgreed: true
      ),
      User(
        userId: "3",
        email: "test3@test.com",
        name: "박민수",
        loginType: .apple,
        fcmToken: "",
        termsAgreed: true,
        privacyAgreed: true
      )
    ],
    filteredMembers: [
      User(
        userId: "3",
        email: "test3@test.com",
        name: "박민수",
        loginType: .apple,
        fcmToken: "",
        termsAgreed: true,
        privacyAgreed: true
      )
    ],
    showMentionPicker: true,
    placeholder: "답글을 입력하세요",
    onSubmit: {},
    onContentChange: { _, _ in },
    onSelectMention: { _ in },
    onSelectAllMentions: {},
    onRemoveTag: { _ in },
    onRemoveAllTags: {},
    onFocusChange: { _ in }
  )
}
