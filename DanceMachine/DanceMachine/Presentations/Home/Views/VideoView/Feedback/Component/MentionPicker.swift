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
      Text("팀원 선택")
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(.white.opacity(0.7))
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)

      ScrollView {
        LazyVStack(alignment: .leading, spacing: 4) {
          // @All 버튼
          Button {
            selectAll()
          } label: {
            HStack(spacing: 8) {
              Text("@All")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)

              Spacer()

              
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
              taggedUsers.count == filteredMembers.count && !filteredMembers.isEmpty
              ? Color.purple.opacity(0.1)
              : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .contentShape(Rectangle())
          }

          ForEach(filteredMembers, id: \.userId) { user in
            Button {
              action(user)
            } label: {
              HStack(spacing: 8) {

                Text(user.name)
                  .font(.system(size: 16))
                  .foregroundStyle(.white)

                Spacer()

              }
              .padding(.horizontal, 16)
              .padding(.vertical, 12)
              .background(
                taggedUsers.contains(where: { $0.userId == user.userId })
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
//      .frame(maxHeight: 160)
      .frame(height: 160)
    }
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.gray)
    )
    .transition(.move(edge: .bottom).combined(with: .opacity))
  }
}

//#Preview {
//  MentionPicker()
//}
