//
//  ReplySheet.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/28/25.
//

import SwiftUI

struct ReplySheet: View {
  @Environment(\.dismiss) private var dismiss
  
  @State private var mM = MentionManager()
  
  @State private var isKeyboardVisible: Bool = false
  
  let reply: [Reply]
  let feedback: Feedback
  let taggedUsers: [User] // 이전화면에서 받아오는 태그 된 유저 (피드백 카드)
  let teamMembers: [User]
  let replyCount: Int
  
  let currentTime: Double
  let startTime: Double
  let timeSeek: () -> Void
  
  let getTaggedUsers: ([String]) -> [User]
  let getAuthorUser: (String) -> User?
  let onReplySubmit: (String, [String]) -> Void
  
  let currentUserId: String
  let onDelete: (String, String) async -> Void
  
  let onFeedbackDelete: () -> Void
  
  @State private var selectedReply: Reply?
  @State private var content: String = ""
  
  private var filteredMembers: [User] {
    if mM.mentionQuery.isEmpty {
      return teamMembers
    }
    return teamMembers.filter {
      $0.name.lowercased().contains(mM.mentionQuery.lowercased())
    }
  }
  
  enum InputMode {
    case none
    case reply
    case rereply
  }
  
  @State private var inputMode: InputMode = .none
  
  var body: some View {
    NavigationStack {
      VStack {
        FeedbackCard(
          feedback: feedback,
          authorUser: getAuthorUser(feedback.authorId),
          taggedUsers: taggedUsers,
          replyCount: replyCount,
          action: {}, // 아무 기능 없음
          showReplySheet: {}, // 아무 기능 없음
          currentTime: currentTime,
          startTime: startTime,
          timeSeek: { timeSeek() },
          currentUserId: currentUserId,
          onDelete: {
            onFeedbackDelete()
            dismiss()
          }
        )
        .padding(.horizontal, 8)
        .overlay(alignment: .bottomLeading) {
          Button {
            self.inputMode = .reply
          } label: {
            Text("답글달기")
              .font(.caption)
              .foregroundStyle(.gray)
          }
          .padding()
        }
        
        Divider()
        
        replyList
      }
      .contentShape(Rectangle())
      .onTapGesture {
        /// 키보드 내리면서 들어가있는 모든 내용들을 초기화 하는 내용입니다.
        self.inputMode = .none
        mM.dismissKeyboardAndClear()
      }
      .animation(.easeInOut(duration: 0.2), value: mM.showPicker)
      .safeAreaInset(edge: .bottom) {
        switch inputMode {
        case .none: // 일반 상태
          inputView
        case .reply: // 피드백에 답글달때
          ReplyRecycle(
            teamMembers: teamMembers,
            replyingTo: getAuthorUser(feedback.authorId),
            onSubmit: { content, taggedIds in
              self.onReplySubmit(content, taggedIds)
              self.inputMode = .none
              mM.dismissKeyboardAndClear()
            },
            refresh: {
              dismissKeyboard()
              self.inputMode = .none
              mM.dismissKeyboardAndClear()
            }
          )
        case .rereply: // 답글에 답글달때
          ReplyRecycle(
            teamMembers: teamMembers,
            replyingTo: getAuthorUser(feedback.authorId),
            onSubmit: { content, taggedIds in
              self.onReplySubmit(content, taggedIds)
              dismissKeyboard()
              self.inputMode = .none
            },
            refresh: {
              self.inputMode = .none
              mM.dismissKeyboardAndClear()
            }
          )
        }
      }
      //      .ignoresSafeArea(edges: .bottom)
      .toolbarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarLeadingBackButton(icon: .xmark)
        ToolbarCenterTitle(text: "댓글")
      }
    }
    .background(Color.white) // FIXME: 다크모드 배경색 명시
  }
  
  private var replyList: some View {
    ScrollView {
      LazyVStack {
        ForEach(reply, id: \.replyId) { reply in
          ReplyCard(
            reply: reply,
            authorUser: getAuthorUser(reply.authorId),
            taggedUsers: getTaggedUsers(reply.taggedUserIds),
            replyAction: {
              self.selectedReply = reply
              self.inputMode = .rereply
            },
            currentUserId: currentUserId,
            onDelete: {
              Task {
                await onDelete(reply.replyId, feedback.feedbackId.uuidString)
              }
            }, // TODO: 삭제
          )
        }
      }
    }
  }
  
  private var inputView: some View {
    VStack(spacing: 8) {
      taggedView
      
      CustomTextField(
        content: $content,
        placeHolder: "답글을 입력해주세요.",
        submitAction: {
          onReplySubmit(
            content, mM.taggedUsers.map { $0.userId }
          )
          self.content = ""
          self.inputMode = .none
          mM.dismissKeyboardAndClear()
        },
        onFocusChange: { focused in
          self.isKeyboardVisible = focused
        },
        autoFocus: false
      )
      .onChange(of: content) { oldValue, newValue in
        mM.handleMention(oldValue: oldValue, newValue: newValue)
      }
    }
    .padding(.vertical, 8)
    .padding(.horizontal, 16)
    .background { // FIXME: 컬러 수정
      if isKeyboardVisible {
        RoundedRectangle(cornerRadius: 20)
          .fill(Color.gray)
      } else {
        Color.gray
          .ignoresSafeArea()
          .overlay(alignment: .top) {
            Rectangle().frame(height: 1.5)
              .foregroundStyle(.white) // FIXME: 다크모드 색 명시
          }
      }
    }
    .overlay(alignment: .bottom) {
      if mM.showPicker {
        MentionPicker(
          filteredMembers: filteredMembers,
          action: {
            mM.selectMention(user: $0)
            self.content = ""
          },
          taggedUsers: mM.taggedUsers
        )
        .padding(.bottom, 60)
      }
    }
  }
  
  private var taggedView: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 4) {
        ForEach(mM.taggedUsers, id: \.userId) { user in
          HStack(spacing: 3) {
            Text("@")
              .font(.system(size: 16)) // FIXME: 폰트 수정
              .foregroundStyle(.blue) // FIXME: 컬러 수정
            Text(user.name)
              .font(.system(size: 16)) // FIXME: 폰트 수정
              .foregroundStyle(.blue) // FIXME: 컬러 수정
            Button {
              mM.taggedUsers.removeAll { $0.userId == user.userId }
            } label: {
              Image(systemName: "xmark.circle.fill")
                .foregroundStyle(Color.gray) // FIXME: 컬러 수정
            }
          }
          .animation(nil, value: mM.taggedUsers)
        }
      }
    }
    .padding(.vertical, 8)
  }
}

#Preview {
  NavigationStack {
    ReplySheet(
      reply: [
        Reply(
          replyId: "1",
          feedbackId: "22",
          authorId: "33",
          content: "dfdfdfsdfasdfadfadfasdfadddddddddddddddddddddddddf",
          taggedUserIds: ["3"]
        ),
        Reply(
          replyId: "2",
          feedbackId: "22",
          authorId: "44",
          content: "dfdfdfsdfasdfadfadfasdfadfdfdfdfsdfasdfadfadfasdfadfdfdfdfsdfasdfadfadfasdfadfdfdfdfsdfasdfadfadfasdfadfdfdfdfsdfasdfadfadfasdfadfdfdfdfsdfasdfadfadfasdfadfdfdfdfsdfasdfadfadfasdfadf",
          taggedUserIds: ["3"]
        ),
        Reply(
          replyId: "3",
          feedbackId: "22",
          authorId: "55",
          content: "dfdfdfsdfasdfadfadfasdfadf",
          taggedUserIds: ["3"]
        ),
        Reply(
          replyId: "4",
          feedbackId: "22",
          authorId: "66",
          content: "dfdfdfsdfasdfadfadfasdfadf",
          taggedUserIds: ["3"]
        ),
        Reply(
          replyId: "5",
          feedbackId: "22",
          authorId: "66",
          content: "dfdfdfsdfasdfadfadfasdfadf",
          taggedUserIds: ["3"]
        )
        
      ],
      feedback: Feedback(
        feedbackId: UUID(),
        videoId: "",
        authorId: "dddd",
        content: "야이 놈아.야이 놈아.야이 놈아.야이 놈아.야이 놈아.야이 놈아.야이 놈아.야이 놈아.야이 놈아.야이 놈아.야이 놈아.야이 놈아,야이 놈아,야이 놈아,야이 놈아,야이 놈아,야이 놈아",
        startTime: 1.44141414,
        endTime: 1.55555,
        createdAt: Date().addingTimeInterval(-60 * 0.5)
      ),
      taggedUsers: [User(
        userId: "1",
        email: "",
        name: "2",
        loginType: LoginType.apple,
        fcmToken: "",
        termsAgreed: true,
        privacyAgreed: true
      )],
      teamMembers: [User(
        userId: "",
        email: "",
        name: "카단",
        loginType: LoginType.apple,
        fcmToken: "",
        termsAgreed: true,
        privacyAgreed: true
      )],
      replyCount: 20,
      currentTime: 30.0,
      startTime: 50.0,
      timeSeek: {},
      getTaggedUsers: { ids in
        let all = [
          User(
            userId: "ddd",
            email: "",
            name: "dddd",
            loginType: LoginType.apple,
            fcmToken: "",
            termsAgreed: true,
            privacyAgreed: true
          ),
          User(
            userId: "ddd",
            email: "",
            name: "dddd",
            loginType: LoginType.apple,
            fcmToken: "",
            termsAgreed: true,
            privacyAgreed: true
          ),
          User(
            userId: "ddd",
            email: "",
            name: "dddd",
            loginType: LoginType.apple,
            fcmToken: "",
            termsAgreed: true,
            privacyAgreed: true
          )
        ]
        return all.filter { ids.contains($0.userId) }
      },
      getAuthorUser: { _ in User.init(userId: "1", email: "", name: "1", loginType: .apple, fcmToken: "", termsAgreed: true, privacyAgreed: true)},
      onReplySubmit: {_,_ in },
      currentUserId: "",
      onDelete: {_,_ in },
      onFeedbackDelete: {}
    )
  }
  .environmentObject(NavigationRouter())
}
