//
//  LandscapeFeedbackPanel.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/16/25.
//

import SwiftUI

struct LandscapeFeedbackPanel: View {
  @Bindable var vm: VideoDetailViewModel

  @Binding var feedbackFilter: FeedbackFilter
  @Binding var pointTime: Double
  @Binding var intervalTime: Double
  @Binding var showFeedbackInput: Bool
  @Binding var scrollProxy: ScrollViewProxy?
  @Binding var feedbackType: FeedbackType

  let filteredFeedback: [Feedback]
  let userId: String
  let videoId: String
  let imageNamespace: Namespace.ID

  @Binding var selectedFeedbackImageURL: String?
  @Binding var showFeedbackImageFull: Bool

  let onFeedbackSelect: (Feedback) -> Void
  let onClose: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      // MARK: 헤더
      HStack(spacing: 0) {
        FeedbackSection(feedbackFilter: $feedbackFilter)
          .padding(.vertical, 10)
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

      Divider().foregroundStyle(.strokeNormal)

      // MARK: 피드백 리스트
      FeedbackListView(
        vm: vm,
        pointTime: $pointTime,
        intervalTime: $intervalTime,
        scrollProxy: $scrollProxy,
        filteredFeedbacks: filteredFeedback,
        userId: userId,
        onFeedbackNavigate: { feedback in
          onFeedbackSelect(feedback)
        },
        imageNamespace: imageNamespace,
        selectedFeedbackImageURL: $selectedFeedbackImageURL,
        showFeedbackImageFull: $showFeedbackImageFull
      )
      .scrollIndicators(.hidden)
    }
    .background(Color.backgroundNormal)
    .safeAreaInset(edge: .bottom) {
      FeedbackButtons(
        landScape: true,
        pointAction: {
          self.feedbackType = .point
          self.pointTime = vm.videoVM.currentTime
          self.showFeedbackInput = true // 텍스트 필드로 변하는 시점
          if vm.videoVM.isPlaying {
            vm.videoVM.togglePlayPause()
          }
        },
        intervalAction: {
          if vm.feedbackVM.isRecordingInterval {
            feedbackType = .interval
            self.intervalTime = vm.videoVM.currentTime
            showFeedbackInput = true
            if vm.videoVM.isPlaying {
              vm.videoVM.togglePlayPause()
            }
          } else {
            feedbackType = .interval
            self.pointTime = vm.videoVM.currentTime
            _ = vm.feedbackVM.handleIntervalButtonType(currentTime: vm.videoVM.currentTime)
          }
        },
        isRecordingInterval: vm.feedbackVM.isRecordingInterval,
        startTime: pointTime.formattedTime(),
        currentTime: vm.videoVM.currentTime.formattedTime(),
        feedbackType: $feedbackType
      )
    }
  }
}
