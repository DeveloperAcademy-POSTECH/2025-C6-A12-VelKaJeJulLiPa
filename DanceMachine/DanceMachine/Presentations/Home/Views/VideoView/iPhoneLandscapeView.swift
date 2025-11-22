//
//  LandscapeView.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/16/25.
//

import SwiftUI
import AVFoundation

/// iPhone 가로모드 입니다.
struct iPhoneLandscapeView: View {
  @Bindable var vm: VideoDetailViewModel
  @Bindable var state: VideoViewState
  
  //  @State private var showSpeedModal: Bool = false
  @State private var selectedFeedbackForReply: Feedback? = nil
  
  let filteredFeedback: [Feedback]
  let userId: String
  let proxy: GeometryProxy
  let videoId: String
  let videoURL: String
  let onCaptureFrame: () -> Void
  let editExistingDrawing: () -> Void
  
  let drawingImageNamespace: Namespace.ID
  let feedbackImageNamespace: Namespace.ID
  
  var body: some View {
    ZStack(alignment: .bottom) {
      HStack(spacing: 0) {
        // MARK: 비디오 + 컨트롤 영역
        ZStack {
          Color.black
          VideoPlayerContainer(
            vm: vm,
            state: state,
            videoId: videoId,
            videoURL: videoURL,
            aspectRatio: 16/9,
            isLandscapeMode: true,
            showFeedbackPanel: state.showFeedbackPanel,
            onDrawingAction: onCaptureFrame,
            onFullscreenToggle: {
              withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                state.exitLandscapeMode()
              }
            },
            onToggleFeedbackPanel: {
              withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                state.showFeedbackPanel.toggle()
              }
            },
            onDragChanged: { value in
              state.dragOffset = value.translation.height
            },
            onDragEnded: { value in
              // 80 이상 드래그하면 세로모드로 전환
              if value.translation.height > 80 {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                  state.exitLandscapeMode()
                }
              }
              // 드래그 취소 시 원위치로
              withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                state.dragOffset = 0
              }
            }
          )
        }
        .frame(width: state.showFeedbackPanel ? proxy.size.width * 0.6 : nil)
        .offset(y: state.showFeedbackPanel ? 0 : state.dragOffset * 0.5)
        .clipped()

        // MARK: 피드백 패널
        if state.showFeedbackPanel {
          ZStack {
            // 피드백 리스트 패널
            if selectedFeedbackForReply == nil {
              FeedbackContainer(
                vm: vm,
                state: state,
                videoId: videoId,
                userId: userId,
                filteredFeedbacks: filteredFeedback,
                iPadLandscape: false,
                drawingImageNamespace: drawingImageNamespace,
                feedbackImageNamespace: feedbackImageNamespace,
                onDrawingAction: onCaptureFrame,
                editExistingDrawing: editExistingDrawing,
                onFeedbackSelect: { feedback in
                  withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedFeedbackForReply = feedback
                  }
                }
              )
              .opacity(selectedFeedbackForReply == nil ? 1 : 0)
              .offset(x: selectedFeedbackForReply == nil ? 0 : -20)
            }

            // 답글 패널
            if let feedback = selectedFeedbackForReply {
              LandscapeReplyView(
                vm: vm,
                feedback: feedback,
                taggedUsers: vm.getTaggedUsers(for: feedback.taggedUserIds),
                teamMembers: vm.teamMembers,
                replyCount: vm.feedbackVM.reply[feedback.feedbackId.uuidString]?.count ?? 0,
                currentTime: state.pointTime,
                startTime: state.intervalTime,
                timeSeek: { vm.videoVM.seekToTime(to: state.pointTime) },
                getTaggedUsers: { ids in vm.getTaggedUsers(for: ids) },
                getAuthorUser: { id in vm.getAuthorUser(for: id) },
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
                    replyId: replyId,
                    from: feedbackId
                  )
                },
                onFeedbackDelete: {
                  Task { await vm.feedbackVM.deleteFeedback(feedback) }
                },
                imageNamespace: feedbackImageNamespace,
                onImageTap: { url in
                  state.selectedFeedbackImageURL = url
                  withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    state.showFeedbackImageFull = true
                  }
                },
                onBack: {
                  withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedFeedbackForReply = nil
                  }
                }
              )
              .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
              ))
            }
          }
          .background(Color.backgroundNormal)
          .frame(width: proxy.size.width * 0.4)
          .clipShape(RoundedRectangle(cornerRadius: 8))
          .transition(.move(edge: .trailing))
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .ignoresSafeArea(.container)
      // MARK: Speed Sheet 오버레이
      if state.showSpeedSheet {
        Color.black.opacity(0.7)
          .ignoresSafeArea()
          .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
              state.showSpeedSheet = false
            }
          }
        
        PlaybackSpeedSheet(
          playbackSpeed: $vm.videoVM.playbackSpeed,
          onSpeedChange: { speed in
            vm.videoVM.setPlaybackSpeed(speed)
          }
        )
        .frame(width: 350, height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .transition(.scale.combined(with: .opacity))
      }
    }
  }
}

//#Preview {
//  LandscapeView()
//}
