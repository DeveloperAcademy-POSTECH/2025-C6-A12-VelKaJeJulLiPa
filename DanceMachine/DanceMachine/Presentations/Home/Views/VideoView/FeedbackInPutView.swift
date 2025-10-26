//
//  FeedbackInPutView.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/25/25.
//

import SwiftUI

struct FeedbackInPutView: View {
  let teamMembers: [User]
  let feedbackType: FeedbackType
  let currentTime: Double
  let startTime: Double?
  let onSubmit: (String, [String]) -> Void
  let refresh: () -> Void
  let timeSeek: () -> Void
  
  @State var taggedUsers: [User] = []
  
  @State private var content: String = ""
  @FocusState private var isFocused: Bool
  
  @State private var mentionQuery: String = ""
  @State private var showMentionPicker: Bool = false
  
  private var filteredMembers: [User] {
    if mentionQuery.isEmpty {
      return teamMembers
    }
    return teamMembers.filter {
      $0.name.lowercased().contains(mentionQuery.lowercased())
    }
  }
  
  var body: some View {
    VStack(spacing: 8) {
      topRow
      taggedView
      textField
    }
    .overlay(alignment: .top) {
      if showMentionPicker {
        mentionPicker
          .offset(y: -51)
          .transition(.move(edge: .bottom).combined(with: .opacity))
      }
    }
    .animation(.easeInOut(duration: 0.2), value: showMentionPicker)
    .onAppear {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        isFocused = true
      }
    }
  }
  
  private var topRow: some View {
    HStack(spacing: 4) {
      switch feedbackType {
      case .point:
        TimestampButton(
          text: "\(currentTime.formattedTime())",
          timeSeek: { timeSeek() }
        )
      case .interval:
        TimestampButton(
          text: "\(currentTime.formattedTime()) ~ \(startTime?.formattedTime() ?? "00:00")",
          timeSeek: { timeSeek() }
        )
      }
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
        Text("초기화")
      }
      .foregroundStyle(.gray) // FIXME: 컬러 수정
    }
  }
  // MARK: 태그된 사용자 표시
  private var taggedView: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 4) {
        ForEach(taggedUsers, id: \.userId) { user in
          HStack(spacing: 0) {
            Text("@")
              .font(.system(size: 16)) // FIXME: 폰트 수정
              .foregroundStyle(.purple) // FIXME: 컬러 수정
            Text(user.name)
              .font(.system(size: 16)) // FIXME: 폰트 수정
              .foregroundStyle(.purple) // FIXME: 컬러 수정
            Button {
              taggedUsers.removeAll { $0.userId == user.userId }
            } label: {
              Image(systemName: "xmark.circle.fill")
                .foregroundStyle(Color.gray.opacity(0.8))
            }
          }
        }
      }
    }
  }
  // MARK: 텍스트 필드
  private var textField: some View {
    TextEditor(text: $content)
      .padding(.vertical, 6)
      .padding(.horizontal, 10)
      .padding(.trailing, 30)
      .focused($isFocused)
      .frame(height: 49)
      .overlay {
        RoundedRectangle(cornerRadius: 20)
          .fill(Color.gray.opacity(0.5)) // FIXME: 컬러 수정
          .stroke(Color.gray.opacity(0.3), lineWidth: 2) // FIXME: 스트로크 수정
          .allowsHitTesting(false)
      }
      .overlay(alignment: .leading) {
        if content.isEmpty {
          Text("피드백을 입력하세요.")
            .padding(.horizontal, 16)
            .foregroundStyle(Color.gray.opacity(0.5))
            .allowsHitTesting(false)
        }
      }
      .overlay(alignment: .trailing) {
        Button {
          // TODO: 전송
          onSubmit(content, taggedUsers.map { $0.userId })
        } label: {
          Image(systemName: "paperplane.fill")
        }
        .padding(.horizontal, 16)
        .zIndex(1)
      }
      .onChange(of: content) { oldValue, newValue in
        handleMention(oldValue: oldValue, newValue: newValue)
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
              selectMention(user: user)
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
      .frame(maxHeight: 160)
    }
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.gray)
    )
  }
  // MARK: @ 감지
  private func handleMention(oldValue: String, newValue: String) {
    if newValue.last == "@" {
      showMentionPicker = true
      mentionQuery = ""
    } else if showMentionPicker {
      // @ 이후 텍스트를 추출
      if let lastAtIndex = newValue.lastIndex(of: "@") {
        let queryStartIndex = newValue.index(after: lastAtIndex)
        if queryStartIndex < newValue.endIndex {
          mentionQuery = String(newValue[queryStartIndex...])
          // 공백 입력 시 멘션 피커 닫음
          if mentionQuery.contains(" ") {
            showMentionPicker = false
            mentionQuery = ""
          }
        }
      } else {
        showMentionPicker = false
        mentionQuery = ""
      }
    }
  }
  
  private func selectMention(user: User) {
    if !taggedUsers.contains(where: { $0.userId == user.userId }) {
      taggedUsers.append(user)
    }
    showMentionPicker = false
    mentionQuery = ""
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
  FeedbackInPutView(
    teamMembers: taggedUsers,
    feedbackType: .interval,
    currentTime: 5.111111,
    startTime: 0.2,
    onSubmit: {_, _ in },
    refresh: {},
    timeSeek: {},
    taggedUsers: taggedUsers
  )
}
