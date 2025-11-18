//
//  TaggedUsersView.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/16/25.
//

import SwiftUI

struct TaggedUsersView: View {
  let taggedUsers: [User]
  let teamMembers: [User]
  let onRemove: (String) -> Void
  let onRemoveAll: () -> Void

  private var isAllTagged: Bool {
    !teamMembers.isEmpty && taggedUsers.count == teamMembers.count
  }

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 4) {
        if isAllTagged {
          // @All 태그 표시
          HStack(spacing: 0) {
            Text("@")
              .font(.headline2Medium)
              .foregroundStyle(.accentBlueStrong)
            Text("All")
              .font(.headline2Medium)
              .foregroundStyle(.accentBlueStrong)
            Button {
              onRemoveAll()
            } label: {
              Image(systemName: "xmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(Color.labelAssitive)
            }
          }
          .animation(nil, value: taggedUsers)
        } else {
          // 개별 태그 표시
          ForEach(taggedUsers, id: \.userId) { user in
            HStack(spacing: 0) {
              Text("@")
                .font(.headline2Medium)
                .foregroundStyle(.accentBlueStrong)
              Text(user.name)
                .font(.headline2Medium)
                .foregroundStyle(.accentBlueStrong)
              Button {
                onRemove(user.userId)
              } label: {
                Image(systemName: "xmark.circle.fill")
                  .font(.system(size: 16))
                  .foregroundStyle(Color.labelAssitive)
              }
            }
            .animation(nil, value: taggedUsers)
          }
        }
      }
    }
  }
}
