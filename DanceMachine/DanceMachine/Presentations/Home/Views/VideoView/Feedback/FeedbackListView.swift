//
//  FeedbackListView.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/16/25.
//

import SwiftUI

struct FeedbackListView: View {
  @Bindable var vm: VideoDetailViewModel
  @Bindable var state: VideoViewState

  @State private var selectedFeedback: Feedback? = nil
  @State private var reportTargetFeedback: Feedback? = nil

  let filteredFeedbacks: [Feedback]
  let userId: String
  let videoId: String

  // 가로모드 네비게이션용 콜백
  var onFeedbackNavigate: ((Feedback) -> Void)? = nil

  // 이미지 전체 화면 관련
  let imageNamespace: Namespace.ID
  
  var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        LazyVStack {
          Color.clear.frame(height: 1).id("topFeedback")
          
          if vm.feedbackVM.isLoading {
            ForEach(0..<3, id: \.self) { _ in
              SkeletonFeedbackCard()
            }
          } else if vm.feedbackVM.feedbacks.isEmpty && !vm.feedbackVM.isLoading {
            emptyView
          } else {
            ForEach(filteredFeedbacks, id: \.feedbackId) { f in
              feedbackCardView(for: f)
            }
          }
          
        }
        .onAppear {
          state.scrollProxy = proxy
        }
        .sheet(item: $selectedFeedback) { feedback in
          NavigationStack {
            ReplySheet(
              reply: vm.feedbackVM.reply[feedback.feedbackId.uuidString] ?? [],
              feedback: feedback,
              taggedUsers: vm.getTaggedUsers(for: feedback.taggedUserIds),
              teamMembers: vm.teamMembers,
              replyCount: vm.feedbackVM.reply[feedback.feedbackId.uuidString]?.count ?? 0,
              currentTime: state.pointTime,
              startTime: state.intervalTime,
              timeSeek: { vm.videoVM.seekToTime(to: state.pointTime) },
              getTaggedUsers: { ids in vm.getTaggedUsers(for: ids) },
              getAuthorUser: { ids in vm.getAuthorUser(for: ids) },
              onReplySubmit: {content, taggedIds in
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
                Task { await vm.feedbackVM.deleteFeedback(feedback) }
              },
              imageNamespace: imageNamespace,
              onImageTap: { url in
                state.selectedFeedbackImageURL = url
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                  state.showFeedbackImageFull = true
                }
              }
            )
          }
        }
        .sheet(item: $reportTargetFeedback) { feedback in
          NavigationStack {
            CreateReportView(
              reportedId: feedback.authorId,
              reportContentType: .feedback,
              feedback: feedback,
              toastReceiveView: ReportToastReceiveViewType.videoView
            )
          }
        }
      }
    }
    .refreshable {
      Task { try await vm.feedbackVM.loadFeedbacks(for: videoId) }
    }
    .scrollIndicators(.hidden)
  }
  
  private var emptyView: some View {
    GeometryReader { g in
      VStack {
        Text("피드백이 없습니다.")
      }
      .frame(width: g.size.width, height: g.size.height)
    }
    .frame(height: 300)
  }

  @ViewBuilder
  private func feedbackCardView(for f: Feedback) -> some View {
    if let navigate = onFeedbackNavigate {
      // 가로모드: 콜백으로 상태 변경
      FeedbackCard(
        feedback: f,
        authorUser: vm.getAuthorUser(for: f.authorId),
        taggedUsers: vm.getTaggedUsers(for: f.taggedUserIds),
        replyCount: vm.feedbackVM.reply[f.feedbackId.uuidString]?.count ?? 0,
        action: { navigate(f) },
        showReplySheet: { navigate(f) },
        currentTime: state.pointTime,
        startTime: state.intervalTime,
        timeSeek: { vm.videoVM.seekToTime(to: f.startTime ?? state.pointTime ) },
        currentUserId: userId,
        onDelete: { Task { await vm.feedbackVM.deleteFeedback(f) } },
        onReport: { }, // 가로모드에서는 신고 비활성화
        imageNamespace: imageNamespace,
        onImageTap: { url in
          state.selectedFeedbackImageURL = url
          withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            state.showFeedbackImageFull = true
          }
        }
      )
    } else {
      // 세로모드: 기존 시트 방식
      FeedbackCard(
        feedback: f,
        authorUser: vm.getAuthorUser(for: f.authorId),
        taggedUsers: vm.getTaggedUsers(for: f.taggedUserIds),
        replyCount: vm.feedbackVM.reply[f.feedbackId.uuidString]?.count ?? 0,
        action: { self.selectedFeedback = f },
        showReplySheet: { self.selectedFeedback = f },
        currentTime: state.pointTime,
        startTime: state.intervalTime,
        timeSeek: { vm.videoVM.seekToTime(to: f.startTime ?? state.pointTime ) },
        currentUserId: userId,
        onDelete: { Task { await vm.feedbackVM.deleteFeedback(f) } },
        onReport: {
          if !state.forceShowLandscape {
            self.reportTargetFeedback = f
          }
        },
        imageNamespace: imageNamespace,
        onImageTap: { url in
          state.selectedFeedbackImageURL = url
          withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            state.showFeedbackImageFull = true
          }
        }
      )
    }
  }
}

//#Preview {
//  FeedbackListView()
//}
