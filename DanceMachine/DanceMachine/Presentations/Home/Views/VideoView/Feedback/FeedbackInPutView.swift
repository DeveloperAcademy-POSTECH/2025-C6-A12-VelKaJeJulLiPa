//
//  FeedbackInPutView.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/25/25.
//

import SwiftUI

struct FeedbackInPutView: View {
  @State private var mM = MentionManager()
  
  let teamMembers: [User]
  let feedbackType: FeedbackType
  let currentTime: Double
  let startTime: Double?
  let onSubmit: (String, [String]) -> Void
  let refresh: () -> Void
  let timeSeek: () -> Void
  
  @State private var content: String = ""
  @FocusState private var isFocused: Bool
  
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
      topRow
      taggedView
      CustomTextField(
        content: $content,
        placeHolder: (
          mM.taggedUsers.isEmpty ? "피드백 받을 사람을 선택해주세요" : "피드백을 입력하세요."
        ),
        submitAction: {
          onSubmit(content, mM.taggedUsers.map { $0.userId })
        },
        onFocusChange: {_ in },
        autoFocus: true
      )
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
            self.content = mM.removeMentionText(from: self.content)
          },
          selectAll: {
            mM.selectAllMembers(members: filteredMembers)
            self.content = mM.removeMentionText(from: self.content)
          },
          taggedUsers: mM.taggedUsers
        )
        .padding(.bottom, 60)
      }
    }
    .animation(.easeInOut(duration: 0.2), value: mM.showPicker)
    .onAppear {
      isFocused = true
    }
  }
  
  private var topRow: some View {
    HStack(spacing: 4) {
      Text("타임 스탬프:")
        .font(.system(size: 14))
        .foregroundStyle(.white)
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
      .foregroundStyle(.white) // FIXME: 컬러 수정
    }
  }
  // MARK: 태그된 사용자 표시
  private var taggedView: some View {
    let isAllTagged = !teamMembers.isEmpty && mM.taggedUsers.count == teamMembers.count

    return ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 4) {
        if isAllTagged {
          // @All 태그 표시
          HStack(spacing: 0) {
            Text("@")
              .font(.system(size: 16)) // FIXME: 폰트 수정
              .foregroundStyle(.purple) // FIXME: 컬러 수정
            Text("All")
              .font(.system(size: 16, weight: .semibold)) // FIXME: 폰트 수정
              .foregroundStyle(.purple) // FIXME: 컬러 수정
            Button {
              mM.taggedUsers.removeAll()
            } label: {
              Image(systemName: "xmark.circle.fill")
                .foregroundStyle(Color.red)
            }
          }
        } else {
          // 개별 태그 표시
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
                  .foregroundStyle(Color.red)
              }
            }
          }
        }
      }
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
  FeedbackInPutView(
    teamMembers: taggedUsers,
    feedbackType: .interval,
    currentTime: 5.111111,
    startTime: 0.2,
    onSubmit: {_, _ in },
    refresh: {},
    timeSeek: {}
  )
}
