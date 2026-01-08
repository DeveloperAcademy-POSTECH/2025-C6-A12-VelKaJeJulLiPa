//
//  FeedbackContainer.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/21/25.
//

import SwiftUI
import StoreKit

/// 피드백 타이틀 + 리스트 + 입력 버튼을 담당하는 컴포넌트 입니다.
struct FeedbackContainer: View {
  @Environment(\.requestReview) private var requestReview
  @Bindable var vm: VideoDetailViewModel
  @Bindable var state: VideoViewState

  let videoId: String
  let userId: String
  let filteredFeedbacks: [Feedback]
  let iPadLandscape: Bool
  let drawingImageNamespace: Namespace.ID
  let feedbackImageNamespace: Namespace.ID
  let onDrawingAction: (() -> Void)? // 드로잉 액션
  let editExistingDrawing: (() -> Void)?
  let onFeedbackSelect: ((Feedback) -> Void)?
  var isSidebarVisible: Bool = true // iPad NavigationSplitView 사이드바 표시 여부

  private var isIPad: Bool {
    UIDevice.current.userInterfaceIdiom == .pad
  }

  private var leadingPadding: CGFloat {
    if isIPad && !isSidebarVisible {
      return 54 // 사이드바 버튼 크기만큼
    }
    return 16
  }

  var body: some View {
    ZStack(alignment: .bottom) {
      VStack(spacing: 0) {
        HStack {
          FeedbackSection(feedbackFilter: $state.feedbackFilter)
            .padding(.leading, leadingPadding)
            .padding(.trailing, 16)
        }
        .padding(.vertical, 10)
        .padding(.top, isIPad && iPadLandscape ? 80 : 0)
        Divider().frame(height: 0)
        // 피드백 리스트
        if vm.feedbackVM.showErrorView {
          ErrorStateView(
            message: vm.feedbackVM.errorMsg ?? "Fatal Error 404",
            action: {
              Task {
                await vm.feedbackVM.loadFeedbacks(for: videoId)
              }
            }
          )
          .frame(maxWidth: .infinity, maxHeight: .infinity )
        } else {
          FeedbackListView(
            vm: vm,
            state: state,
            filteredFeedbacks: filteredFeedbacks,
            userId: userId,
            videoId: videoId,
            onFeedbackNavigate: onFeedbackSelect,
            imageNamespace: feedbackImageNamespace
          )
        }
      }
      .background(Color.backgroundNormal)
      .contentShape(Rectangle())
      .simultaneousGesture(
        TapGesture()
          .onEnded {
            if state.showFeedbackInput {
              state.showFeedbackInput = false
              dismissKeyboard()
            }
          }
      )

      if !state.isImageOverlayPresented {
        feedbackInputSection
      }
    }
  }

  @ViewBuilder
  private var feedbackInputSection: some View {
    if state.showFeedbackInput {
      FeedbackInPutView(
        teamMembers: vm.teamMembers,
        feedbackType: state.feedbackType,
        currentTime: state.pointTime,
        startTime: state.intervalTime,
        onSubmit: { content, taggedUserId in
          Task {
            if state.feedbackType == .point {
              await vm.feedbackVM.createPointFeedback(
                videoId: videoId,
                authorId: userId,
                content: content,
                taggedUserIds: taggedUserId,
                atTime: state.pointTime,
                image: state.editedOverlayImage
              )
            } else {
              await vm.feedbackVM.createIntervalFeedback(
                videoId: videoId,
                authorId: userId,
                content: content,
                taggedUserIds: taggedUserId,
                startTime: vm.feedbackVM.intervalStartTime ?? 0,
                endTime: vm.videoVM.currentTime,
                image: state.editedOverlayImage
              )
            }
            state.showFeedbackInput = false
            ReviewRequestHelper.incrementFeedbackCountAndRequestReviewIfNeeded(requestReview: requestReview)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
              withAnimation {
                state.scrollProxy?.scrollTo("topFeedback", anchor: .top)
              }
            }
          }
        },
        refresh: {
          state.showFeedbackInput = false
          dismissKeyboard()
        },
        timeSeek: { vm.videoVM.seekToTime(to: state.pointTime) },
        drawingButtonTapped: { onDrawingAction?() },
        editDrawingTapped: { editExistingDrawing?() },
        feedbackDrawingImage: $state.editedOverlayImage,
        imageNamespace: drawingImageNamespace,
        showImageFull: $state.showDrawingImageFull
      )
    } else {
      FeedbackButtons(
        landScape: true,
        pointAction: {
          state.feedbackType = .point
          state.pointTime = vm.videoVM.currentTime
          state.showFeedbackInput = true
          if vm.videoVM.isPlaying {
            vm.videoVM.togglePlayPause()
          }
        },
        intervalAction: {
          if vm.feedbackVM.isRecordingInterval {
            if let startTime = vm.feedbackVM.intervalStartTime,
               vm.videoVM.currentTime < startTime {
              NotificationCenter.post(.video(.showIntervalWarning))
              return
            }
            state.feedbackType = .interval
            state.intervalTime = vm.videoVM.currentTime
            state.showFeedbackInput = true
            _ = vm.feedbackVM.handleIntervalButtonType(currentTime: vm.videoVM.currentTime)
            if vm.videoVM.isPlaying {
              vm.videoVM.togglePlayPause()
            }
          } else {
            state.feedbackType = .interval
            state.pointTime = vm.videoVM.currentTime
            _ = vm.feedbackVM.handleIntervalButtonType(currentTime: vm.videoVM.currentTime)
          }
        },
        isRecordingInterval: vm.feedbackVM.isRecordingInterval,
        startTime: state.pointTime.formattedTime(),
        currentTime: vm.videoVM.currentTime.formattedTime(),
        feedbackType: $state.feedbackType
      )
    }
  }
}

//#Preview {
//  FeedbackContainer()
//}
