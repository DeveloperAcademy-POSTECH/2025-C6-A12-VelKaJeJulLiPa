//
//  FeedbackInPutView.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/25/25.
//

import SwiftUI

struct FeedbackInPutView: View {
  
  @EnvironmentObject private var router: MainRouter
  
  @State private var mM = MentionManager()
  
  let teamMembers: [User]
  let feedbackType: FeedbackType
  let currentTime: Double
  let startTime: Double?
  let onSubmit: (String, [String]) -> Void
  let refresh: () -> Void
  let timeSeek: () -> Void
  
  let drawingButtonTapped: () -> Void
  
  @State private var content: String = ""
  @FocusState private var isFocused: Bool

  
  @Binding var feedbackDrawingImage: UIImage? // 드로잉 피드백 이미지
  let imageNamespace: Namespace.ID
  @Binding var showImageFull: Bool
  
  private var filteredMembers: [User] {
    if mM.mentionQuery.isEmpty {
      return teamMembers
    }
    return teamMembers.filter {
      $0.name.lowercased().contains(mM.mentionQuery.lowercased())
    }
  }
  
  var body: some View {
    VStack(spacing: 16) {
      topRow
      if feedbackDrawingImage != nil {
        feedbackImageView.frame(maxWidth: .infinity, alignment: .leading)
      }
      if !mM.taggedUsers.isEmpty {
        TaggedUsersView(
          taggedUsers: mM.taggedUsers,
          teamMembers: teamMembers,
          onRemove: { userId in
            mM.taggedUsers.removeAll { $0.userId == userId }
          },
          onRemoveAll: { mM.taggedUsers.removeAll() }
        )
      }
      CustomTextField(
        content: $content,
        placeHolder: (
          mM.taggedUsers.isEmpty ? "@팀원 태그" : "피드백을 입력하세요."
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
    .padding([.vertical, .horizontal], 16)
    .background(
      RoundedRectangle(cornerRadius: 20)
        .fill(Color.backgroundElevated)
    )
    .animation(.easeInOut(duration: 0.2), value: content.count)
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
        .padding(.bottom, 65)
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
        .font(.headline2Medium)
        .foregroundStyle(.labelNormal)
      switch feedbackType {
      case .point:
        TimestampInput(
          text: "\(currentTime.formattedTime())",
          timeSeek: { timeSeek() }
        )
      case .interval:
        TimestampInput(
          text: "\(currentTime.formattedTime()) ~ \(startTime?.formattedTime() ?? "00:00")",
          timeSeek: { timeSeek() }
        )
      }
      Spacer()
      
      // TODO: 여기에 드로잉 버튼으로 갈 이미지 삽입
      Button {
        drawingButtonTapped()
      } label: {
        Text("드로잉 이동")
      }
      
      clearButton
    }
  }
  
  private var clearButton: some View {
    Button {
      refresh()
    } label: {
      Image(systemName: "xmark")
        .font(.system(size: 17))
        .foregroundStyle(.labelNormal)
    }
  }
  
  // MARK: - 피드백 이미지
  private var feedbackImageView: some View {
    VStack(alignment: .leading) {
      if let image = feedbackDrawingImage {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
          .frame(width: 100, height: 100)
          .clipShape(RoundedRectangle(cornerRadius: 8))
          .matchedGeometryEffect(id: "feedbackImage", in: imageNamespace)
          .onTapGesture {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
              showImageFull = true
            }
          }
      }
    }
  }
}

//#Preview {
//  @Previewable @State var taggedUsers: [User] = .init(
//    [User(
//      userId: "1",
//      email: "",
//      name: "서영",
//      loginType: LoginType.apple,
//      fcmToken: "",
//      termsAgreed: true,
//      privacyAgreed: true
//    ),
//     User(
//      userId: "2",
//      email: "",
//      name: "카단",
//      loginType: LoginType.apple,
//      fcmToken: "",
//      termsAgreed: true,
//      privacyAgreed: true
//     ),
//     User(
//      userId: "3",
//      email: "",
//      name: "벨코",
//      loginType: LoginType.apple,
//      fcmToken: "",
//      termsAgreed: true,
//      privacyAgreed: true
//     )]
//  )
//  FeedbackInPutView(
//    teamMembers: taggedUsers,
//    feedbackType: .interval,
//    currentTime: 5.111111,
//    startTime: 0.2,
//    onSubmit: {_, _ in },
//    refresh: {},
//    timeSeek: {},
//    drawingButtonTapped: {},
//    feedbackDrawingImage: .constant(nil)
//  )
//}
