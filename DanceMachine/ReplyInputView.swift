//
//  ReplyInputView.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/28/25.
//

import SwiftUI

struct ReplyInputView: View {
  @State private var mM = MentionManager()
  
  let teamMembers: [User]
  let replyingTo: String
  let onSubmit: (String, [String]) -> Void
  
  @State private var content: String = ""
  @State private var taggedUsers: [User] = []
//  @State private var showMentionPicker: Bool = false
  @State private var mentionQuery: String = ""
  @FocusState private var isInputFocused: Bool
  
  var filteredMembers: [User] {
    guard !mentionQuery.isEmpty else { return teamMembers }
    return teamMembers.filter { $0.name.lowercased().contains(mentionQuery.lowercased()) }
  }
  
  var body: some View {
    VStack(spacing: 8) {
      // 답글 대상 표시
      HStack {
        Text("@\(replyingTo)에게 답글 남기는중")
          .font(.system(size: 14))
          .foregroundColor(.secondary)
        Spacer()
      }
      
      // 태그된 유저 표시
      if !taggedUsers.isEmpty {
        taggedView
      }
      
      // 텍스트 필드
      CustomTextField(
        content: $content,
        placeHolder: "답글을 입력해주세요.",
        submitAction: { onSubmit(content, taggedUsers.map { $0.userId }) },
        autoFocus: true
      )
      .onChange(of: content) { oldValue, newValue in
        mM.handleMention(oldValue: oldValue, newValue: newValue)
      }
    }
    .frame(maxHeight: 140)
    .overlay(alignment: .top) {
      if mM.showPicker {
        MentionPicker(
          filteredMembers: filteredMembers,
          action: {
            mM.selectMention(user: $0)
            self.content = ""
          },
          taggedUsers: taggedUsers
        )
      }
    }
    .animation(.easeInOut(duration: 0.2), value: mM.showPicker)
    .onAppear {
      isInputFocused = true
    }
  }
  
  // MARK: 태그된 유저 표시
  private var taggedView: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 4) {
        ForEach(taggedUsers, id: \.userId) { user in
          HStack(spacing: 4) {
            Text("@\(user.name)")
              .font(.system(size: 16)) // FIXME: 폰트 수정
              .foregroundStyle(.purple) // FIXME: 컬러 수정
            Button {
              taggedUsers.removeAll { $0.userId == user.userId }
            } label: {
              Image(systemName: "xmark.circle.fill")
                .font(.system(size: 14))
            }
          }
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
                    taggedUsers.contains(where: { $0.userId == user.userId })
                    ? .purple
                    : .gray
                  )
                
                Text(user.name)
                  .font(.system(size: 16))
                  .foregroundStyle(.white)
                
                Spacer()
                
                if taggedUsers.contains(where: { $0.userId == user.userId }) {
                  Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.purple)
                }
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
      .frame(maxHeight: 200)
    }
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.gray)
    )
  }
}


//#Preview {
//  ReplyInputView()
//}
