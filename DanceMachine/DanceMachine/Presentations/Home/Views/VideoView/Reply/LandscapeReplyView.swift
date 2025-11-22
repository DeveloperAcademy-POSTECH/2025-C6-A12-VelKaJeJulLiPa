//
//  LandscapeReplyView.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/16/25.
//

import SwiftUI

struct LandscapeReplyView: View {
  @Bindable var vm: VideoDetailViewModel

  let feedback: Feedback
  let taggedUsers: [User]
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
  let imageNamespace: Namespace.ID
  let onImageTap: (String) -> Void
  let onBack: () -> Void

  @State private var mM = MentionManager()
  @State private var content: String = ""
  @State private var isKeyboardVisible: Bool = false
  @State private var reportTargetReply: Reply? = nil
  @State private var showCreateReportSuccessToast: Bool = false

  enum InputMode {
    case none
    case reply
    case rereply
  }

  @State private var inputMode: InputMode = .none
  @State private var selectedReply: Reply?

  private var filteredMembers: [User] {
    if mM.mentionQuery.isEmpty {
      return teamMembers
    }
    return teamMembers.filter {
      $0.name.lowercased().contains(mM.mentionQuery.lowercased())
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      // MARK: 답글 헤더
      HStack(spacing: 8) {
        Button {
          withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            onBack()
          }
        } label: {
          Image(systemName: "chevron.left")
            .font(.system(size: 20))
            .foregroundStyle(.labelStrong)
        }
        .frame(width: 33, height: 33)
        .contentShape(Rectangle())

        Text("댓글")
          .font(.headline2Medium)
          .foregroundStyle(.labelNormal)
        Spacer()
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 10)

      Divider().frame(height: 0)

      ScrollView {
        LazyVStack(spacing: 0) {
          // 피드백 카드
          FeedbackCard(
            feedback: feedback,
            authorUser: getAuthorUser(feedback.authorId),
            taggedUsers: taggedUsers,
            replyCount: replyCount,
            action: {},
            showReplySheet: {},
            currentTime: currentTime,
            startTime: startTime,
            timeSeek: { timeSeek() },
            currentUserId: currentUserId,
            onDelete: {
              onFeedbackDelete()
              onBack()
            },
            onReport: { }, // 가로모드에서는 신고 비활성화
            showBottomReplyButton: true,
            onBottomReplyTap: {
              self.inputMode = .reply
            },
            imageNamespace: imageNamespace,
            onImageTap: { url in
              onImageTap(url)
            }
          )
          .contentShape(Rectangle())
          .onTapGesture {
            self.inputMode = .none
            mM.dismissKeyboardAndClear()
          }

          // 답글 리스트
          ForEach(vm.feedbackVM.reply[feedback.feedbackId.uuidString] ?? [], id: \.replyId) { reply in
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
              },
              showCreateReportSheet: { self.reportTargetReply = reply }
            )
          }
        }
      }
    }
    .contentShape(Rectangle())
    .onTapGesture {
      self.inputMode = .none
      mM.dismissKeyboardAndClear()
    }
    .safeAreaInset(edge: .bottom) {
      switch inputMode {
      case .none:
        inputView
      case .reply:
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
      case .rereply:
        ReplyRecycle(
          teamMembers: teamMembers,
          replyingTo: selectedReply.flatMap { getAuthorUser($0.authorId) },
          onSubmit: { content, taggedIds in
            self.onReplySubmit(content, taggedIds)
            self.inputMode = .none
            mM.dismissKeyboardAndClear()
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
      bottomPadding: 63,
      content: {
        ToastView(text: "신고가 접수되었습니다.\n조치사항은 이메일로 안내해드리겠습니다.", icon: .check)
      }
    )
    .onReceive(NotificationCenter.publisher(for: .toast(.reportSuccess))) { notification in
      if let toastViewName = notification.userInfo?["toastViewName"] as? ReportToastReceiveViewType,
         toastViewName == ReportToastReceiveViewType.replySheet {
        showCreateReportSuccessToast = true
      }
    }
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
    .background(Color.backgroundNormal)
  }

  private var inputView: some View {
    ReplySheetInputView(
      content: $content,
      isKeyboardVisible: $isKeyboardVisible,
      taggedUsers: mM.taggedUsers,
      teamMembers: teamMembers,
      filteredMembers: filteredMembers,
      showMentionPicker: mM.showPicker,
      placeholder: "댓글을 입력해 주세요.",
      onSubmit: {
        onReplySubmit(content, mM.taggedUsers.map { $0.userId })
        self.content = ""
        self.inputMode = .none
        mM.dismissKeyboardAndClear()
      },
      onContentChange: { oldValue, newValue in
        mM.handleMention(oldValue: oldValue, newValue: newValue)
      },
      onSelectMention: { user in
        mM.selectMention(user: user)
        self.content = mM.removeMentionText(from: self.content)
      },
      onSelectAllMentions: {
        mM.selectAllMembers(members: filteredMembers)
        self.content = mM.removeMentionText(from: self.content)
      },
      onRemoveTag: { userId in
        mM.taggedUsers.removeAll { $0.userId == userId }
      },
      onRemoveAllTags: {
        mM.taggedUsers.removeAll()
      },
      onFocusChange: { focused in
        self.isKeyboardVisible = focused
      }
    )
  }
}
