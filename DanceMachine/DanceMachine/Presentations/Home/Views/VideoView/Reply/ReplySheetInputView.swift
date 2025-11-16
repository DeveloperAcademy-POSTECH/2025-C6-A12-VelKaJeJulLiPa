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
        .padding(.bottom, 65)
      }
    }
  }
}
