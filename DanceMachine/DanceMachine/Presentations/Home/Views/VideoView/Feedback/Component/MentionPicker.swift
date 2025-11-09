//
//  MentionPicker.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/28/25.
//

import SwiftUI

/// @팀원 선택하는 멘션 피커 컴포넌트 입니다.
struct MentionPicker: View { // FIXME: 디자인 필요
  let filteredMembers: [User]
  let action: (User) -> Void
  let selectAll: () -> Void // 팀원 전체 태그
  
  var taggedUsers: [User]
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 4) {
          allButton
          memberButton
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
      }
      .frame(height: 170)
    }
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(.backgroundElevated)
    )
    .padding(.horizontal, 8)
//    .transition(.move(edge: .bottom).combined(with: .opacity))
  }
  
  private var allButton: some View {
    Button {
      selectAll()
    } label: {
      Text("@All")
        .font(.headline2Medium)
        .foregroundStyle(.labelStrong)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 8)
    .padding(.vertical, 12)
    .background(
      taggedUsers.count == filteredMembers.count && !filteredMembers.isEmpty
      ? Color.fillAssitive
      : Color.clear
    )
    .clipShape(RoundedRectangle(cornerRadius: 10))
    .contentShape(Rectangle())
  }
  
  private var memberButton: some View {
    ForEach(filteredMembers, id: \.userId) { user in
      Button {
        action(user)
      } label: {
        Text(user.name)
          .font(.headline2Medium)
          .foregroundStyle(.labelStrong)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 8)
      .padding(.vertical, 12)
      .background(
        taggedUsers.contains(where: { $0.userId == user.userId })
        ? Color.fillAssitive
        : Color.clear
      )
      .clipShape(RoundedRectangle(cornerRadius: 10))
      .contentShape(Rectangle())
    }
  }
}

#Preview {
  let mock = [
    User(
      userId: "1",
      email: "",
      name: "2",
      loginType: LoginType.apple,
      fcmToken: "",
      termsAgreed: true,
      privacyAgreed: true
    ),
    User(
      userId: "2",
      email: "",
      name: "2",
      loginType: LoginType.apple,
      fcmToken: "",
      termsAgreed: true,
      privacyAgreed: true
    ),
    User(
      userId: "3",
      email: "",
      name: "2",
      loginType: LoginType.apple,
      fcmToken: "",
      termsAgreed: true,
      privacyAgreed: true
    ),
    User(
      userId: "4",
      email: "",
      name: "2",
      loginType: LoginType.apple,
      fcmToken: "",
      termsAgreed: true,
      privacyAgreed: true
    )]
  
  MentionPicker(
    filteredMembers: mock,
    action: {_ in },
    selectAll: {},
    taggedUsers: mock
  )
}
