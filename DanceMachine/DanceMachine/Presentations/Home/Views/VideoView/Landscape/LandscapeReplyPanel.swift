//
//  LandscapeReplyPanel.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/16/25.
//

import SwiftUI

struct LandscapeReplyPanel: View {
  @Bindable var vm: VideoDetailViewModel

  let feedback: Feedback
  @Binding var pointTime: Double
  @Binding var intervalTime: Double
  let userId: String
  let imageNamespace: Namespace.ID

  @Binding var selectedFeedbackImageURL: String?
  @Binding var showFeedbackImageFull: Bool

  @Binding var showInputView: Bool

  let onBack: () -> Void
  let onClose: () -> Void

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

        Button {
          withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            onClose()
          }
        } label: {
          Image(systemName: "xmark.circle")
            .font(.system(size: 20))
            .foregroundStyle(.labelStrong)
        }
        .frame(width: 33, height: 33)
        .contentShape(Rectangle())
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 10)

      Divider().foregroundStyle(.strokeNormal)

      // MARK: 답글 뷰
      LandscapeReplyView(
        vm: vm,
        feedback: feedback,
        taggedUsers: vm.getTaggedUsers(for: feedback.taggedUserIds),
        teamMembers: vm.teamMembers,
        replyCount: vm.feedbackVM.reply[feedback.feedbackId.uuidString]?.count ?? 0,
        currentTime: pointTime,
        startTime: intervalTime,
        timeSeek: { vm.videoVM.seekToTime(to: pointTime) },
        getTaggedUsers: { ids in vm.getTaggedUsers(for: ids) },
        getAuthorUser: { ids in vm.getAuthorUser(for: ids) },
        onReplySubmit: { content, taggedIds in
          Task {
            await vm.feedbackVM.addReply(
              to: feedback.feedbackId.uuidString,
              authorId: userId,
              content: content,
              taggedUserIds: taggedIds
            )
          }
        },
        currentUserId: userId,
        onDelete: { replyId, feedbackId in
          await vm.feedbackVM.deleteReply(
            replyId: replyId, from: feedbackId)
        },
        onFeedbackDelete: {
          Task {
            await vm.feedbackVM.deleteFeedback(feedback)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
              onBack()
            }
          }
        },
        imageNamespace: imageNamespace,
        onImageTap: { url in
          selectedFeedbackImageURL = url
          withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            showFeedbackImageFull = true
          }
        },
        onDismiss: {
          withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            onBack()
          }
        },
        showInputView: $showInputView
      )
    }
    .background(Color.backgroundNormal)
  }
}
