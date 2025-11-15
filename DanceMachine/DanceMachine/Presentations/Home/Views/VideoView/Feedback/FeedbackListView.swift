//
//  FeedbackListView.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/16/25.
//

import SwiftUI

struct FeedbackListView: View {
  @Bindable var vm: VideoDetailViewModel
  
  @Binding var pointTime: Double
  @Binding var intervalTime: Double
  
  @State private var scrollProxy: ScrollViewProxy? = nil
  
  @State private var selectedFeedback: Feedback? = nil
  @State private var reportTargetFeedback: Feedback? = nil
  
  @Namespace private var feedbackImageNamespace
  @State private var selectedFeedbackImageURL: String? = nil
  @State private var showFeedbackImageFull: Bool = false
  
  let filteredFeedbacks: [Feedback]
  let userId: String
  
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
              FeedbackCard(
                feedback: f,
                authorUser: vm.getAuthorUser(for: f.authorId),
                taggedUsers:
                  vm.getTaggedUsers(for: f.taggedUserIds),
                replyCount: vm.feedbackVM.reply[f.feedbackId.uuidString]?.count ?? 0,
                action: { self.selectedFeedback = f },
                showReplySheet: { self.selectedFeedback = f },
                currentTime: pointTime,
                startTime: intervalTime,
                timeSeek: { vm.videoVM.seekToTime(to: f.startTime ?? self.pointTime ) },
                currentUserId: userId,
                onDelete: { Task { await vm.feedbackVM.deleteFeedback(f) } },
                onReport: {
                  if !vm.forceShowLandscape { // 가로모드 시트 x
                    self.reportTargetFeedback = f
                  }
                },
                imageNamespace: feedbackImageNamespace,
                onImageTap: { url in
                  self.selectedFeedbackImageURL = url
                  withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    self.showFeedbackImageFull = true
                  }
                }
              )
            }
          }
          
        }
        .onAppear {
          self.scrollProxy = proxy
        }
        .sheet(item: $selectedFeedback) { feedback in
          ReplySheet(
            reply: vm.feedbackVM.reply[feedback.feedbackId.uuidString] ?? [],
            feedback: feedback,
            taggedUsers: vm.getTaggedUsers(for: feedback.taggedUserIds),
            teamMembers: vm.teamMembers,
            replyCount: vm.feedbackVM.reply[feedback.feedbackId.uuidString]?.count ?? 0,
            currentTime: pointTime,
            startTime: intervalTime,
            timeSeek: { vm.videoVM.seekToTime(to: self.pointTime) },
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
            imageNamespace: feedbackImageNamespace,
            onImageTap: { url in
              self.selectedFeedbackImageURL = url
              withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                self.showFeedbackImageFull = true
              }
            },
            onDismiss: nil
          )
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
}

//#Preview {
//  FeedbackListView()
//}
