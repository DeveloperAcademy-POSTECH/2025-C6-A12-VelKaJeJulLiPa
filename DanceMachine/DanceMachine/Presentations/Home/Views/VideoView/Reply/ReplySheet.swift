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
  
  @State private var isReportSheetPresented: Bool = false
  @State private var showCreateReportSuccessToast: Bool = false
  
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
  @State private var reportTargetReply: Reply?
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
          },
          onReport: { isReportSheetPresented = true }
        )
        .overlay(alignment: .bottomLeading) {
          Button {
            self.inputMode = .reply
          } label: {
            Text("답글달기")
              .font(.caption1Medium)
              .foregroundStyle(.labelNormal)
          }
          .padding()
        }
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
      .toast(
        isPresented: $showCreateReportSuccessToast,
        duration: 3,
        position: .bottom,
        bottomPadding: 63, // FIXME: 신고하기 - 하단 공백 조정 필요
        content: {
          ToastView(text: "신고가 접수되었습니다.\n조치사항은 이메일로 안내해드리겠습니다.", icon: .check)
        }
      )
      // MARK: 신고 완료 토스트 리시버
      .onReceive(NotificationCenter.default.publisher(for: .showCreateReportSuccessToast)) { notification in
        if let toastViewName = notification.userInfo?["toastViewName"] as? ReportToastReceiveViewType,
           toastViewName == ReportToastReceiveViewType.replySheet {
          showCreateReportSuccessToast = true
        }
      }
      
      // 신고하기 시트 - 피드백
      .sheet(isPresented: $isReportSheetPresented) {
        NavigationStack {
          CreateReportView(
            reportedId: feedback.authorId,
            reportContentType: .feedback,
            feedback: feedback,
            toastReceiveView: ReportToastReceiveViewType.replySheet
          )
        }
      }
      
      // 신고하기 - 답글
      .sheet(item: $reportTargetReply) { reply in
        NavigationStack {
          CreateReportView(
            reportedId: reply.authorId,
            reportContentType: .reply,
            reply: reply,
            toastReceiveView: ReportToastReceiveViewType.replySheet
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
    .background(Color.fillNormal)
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
            showCreateReportSheet: { self.reportTargetReply = reply }
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
        placeHolder: mM.taggedUsers.isEmpty ? "@팀원 태그" : "답글을 입력해주세요.",
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
    .padding([.vertical, .horizontal], 16)
    .background { // FIXME: 컬러 수정
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
  }
  
  private var taggedView: some View {
    let isAllTagged = !teamMembers.isEmpty && mM.taggedUsers.count == teamMembers.count

    return ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 4) {
        if isAllTagged {
          // @All 태그 표시
          HStack(spacing: 4) {
            Text("@")
              .font(.headline2Medium)
              .foregroundStyle(.accentBlueStrong)
            Text("All")
              .font(.headline2Medium)
              .foregroundStyle(.accentBlueStrong)
            Button {
              mM.taggedUsers.removeAll()
            } label: {
              Image(systemName: "xmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(Color.labelAssitive)
            }
          }
          .animation(nil, value: mM.taggedUsers)
        } else {
          // 개별 태그 표시
          ForEach(mM.taggedUsers, id: \.userId) { user in
            HStack(spacing: 3) {
              Text("@")
                .font(.headline2Medium)
                .foregroundStyle(.accentBlueStrong)
              Text(user.name)
                .font(.headline2Medium)
                .foregroundStyle(.accentBlueStrong)
              Button {
                mM.taggedUsers.removeAll { $0.userId == user.userId }
              } label: {
                Image(systemName: "xmark.circle.fill")
                  .font(.system(size: 16))
                  .foregroundStyle(Color.labelAssitive)
              }
            }
            .animation(nil, value: mM.taggedUsers)
          }
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
        createdAt: Date().addingTimeInterval(-60 * 0.5),
        teamspaceId: ""
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
  .environmentObject(MainRouter())
}
