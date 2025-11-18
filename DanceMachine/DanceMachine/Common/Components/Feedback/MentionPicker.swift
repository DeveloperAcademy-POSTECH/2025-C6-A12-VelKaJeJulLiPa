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
      if filteredMembers.isEmpty {
        emptyView
      } else {
        ScrollView {
          LazyVStack(alignment: .leading, spacing: 4) {
            allButton
            memberButton
          }
          .padding(.horizontal, 8)
          .padding(.vertical, 8)
        }
        .frame(maxHeight: 170)
      }
    }
    .frame(height: filteredMembers.isEmpty ? nil : calculateHeight())
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(.backgroundElevated)
    )
    .padding(.horizontal, 8)
    .contentShape(Rectangle())
//    .transition(.move(edge: .bottom).combined(with: .opacity))
  }

  private var emptyView: some View {
    Text("팀원이 없습니다. 팀원을 초대해주세요")
      .font(.headline2Medium)
      .foregroundStyle(.labelAssitive)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 20)
  }

  private func calculateHeight() -> CGFloat {
    let itemHeight: CGFloat = 44 // 패딩 포함한 각 항목 높이
    let padding: CGFloat = 16 // 상하 패딩
    let itemCount = filteredMembers.count + 1 // @All 버튼 포함
    let contentHeight = CGFloat(itemCount) * itemHeight + padding

    return min(contentHeight, 170) // 최대 170, 최소는 컨텐츠 높이
  }
  
  private var allButton: some View {
    Button {
      selectAll()
    } label: {
      Text("@All")
        .font(.headline2Medium)
        .foregroundStyle(.labelStrong)
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
    .buttonStyle(.plain)
  }
  
  private var memberButton: some View {
    ForEach(filteredMembers, id: \.userId) { user in
      Button {
        action(user)
      } label: {
        Text(user.name)
          .font(.headline2Medium)
          .foregroundStyle(.labelStrong)
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
      .buttonStyle(.plain)
    }
  }
}

#Preview {
  let mock = [
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
    filteredMembers: [],
    action: {_ in },
    selectAll: {},
    taggedUsers: mock
  )
}
