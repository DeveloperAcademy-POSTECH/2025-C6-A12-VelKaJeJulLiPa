//
//  PortraitView.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/16/25.
//

import SwiftUI
import AVFoundation

/// iPhone 세로모드 입니다.
struct iPhonePortraitView: View {
  @Bindable var vm: VideoDetailViewModel
  @Bindable var state: VideoViewState
  
  let filteredFeedback: [Feedback]
  let userId: String
  let proxy: GeometryProxy
  let videoTitle: String
  let videoId: String
  let videoURL: String
  
  let drawingImageNamespace: Namespace.ID
  let feedbackImageNamespace: Namespace.ID
  
  let onCaptureFrame: () -> Void
  let editExistingDrawing: () -> Void
  
  var body: some View {
    VStack(spacing: 0) {
      // 비디오 플레이어
      VideoPlayerContainer(
        vm: vm,
        state: state,
        videoId: videoId,
        videoURL: videoURL,
        aspectRatio: 16/9,
        isLandscapeMode: false,
        showFeedbackPanel: false,
        onDrawingAction: onCaptureFrame, // TODO: 여기도 위에 수정하면서 같이 수정하기
        onFullscreenToggle: {
          withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            state.enterLandscapeMode()
          }
        },
        onToggleFeedbackPanel: {},
        onDragChanged: { value in
          state.dragOffset = value.translation.height
        },
        onDragEnded: { value in
          // -80 이하로 드래그하면 전체화면으로 전환
          if value.translation.height < -80 {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
              state.enterLandscapeMode()
            }
          }
          // 드래그 취소 시 원위치로
          withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            state.dragOffset = 0
          }
        }
      )
      .frame(height: proxy.size.width * 9 / 16)
      .offset(y: state.dragOffset * 0.5)
      // 피드백 컨테이너
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
        onFeedbackSelect: nil
      )
    }
    .sheet(isPresented: $state.showSpeedSheet) {
      PlaybackSpeedSheet(
        playbackSpeed: $vm.videoVM.playbackSpeed,
        onSpeedChange: { speed in
          vm.videoVM.setPlaybackSpeed(speed)
        }
      )
      .presentationDetents([.fraction(0.25)])
    }
    .background(Color.backgroundNormal.ignoresSafeArea())
    .toolbarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarLeadingBackButton(icon: .chevron)
      ToolbarCenterTitle(text: videoTitle)
    }
  }
}

//#Preview {
//  PortraitView()
//}
