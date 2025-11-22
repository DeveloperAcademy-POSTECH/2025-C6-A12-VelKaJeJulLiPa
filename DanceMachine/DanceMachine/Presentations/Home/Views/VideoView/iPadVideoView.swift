//
//  iPadVideoView.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/22/25.
//

import SwiftUI

struct iPadVideoView: View {
  @Bindable var vm: VideoDetailViewModel
  @Bindable var state: VideoViewState
  
  let videoId: String
  let videoTitle: String
  let videoURL: String
  let userId: String
  let filteredFeedbacks: [Feedback]
  let proxy: GeometryProxy
  let drawingImageNamespace: Namespace.ID
  let feedbackImageNamespace: Namespace.ID
  let onCaptureFrame: () -> Void
  let editExistingDrawing: () -> Void
  
  @State private var columnVisibility: NavigationSplitViewVisibility = .all
  @State private var showFullScreen: Bool = false
  @State private var isDeviceLandscape: Bool = false
  @State private var lastSize: CGSize = .zero

  var body: some View {
    ZStack {
      // 일반 레이아웃
      Group {
        if isDeviceLandscape {
          // 기기가 가로모드
          landscapeView
        } else {
          // 기기가 세로모드
          portraitView
        }
      }
      .opacity(showFullScreen ? 0 : 1)

      // 전체화면 레이아웃
      if showFullScreen {
        fullScreenView
          .transition(.opacity)
      }

      // MARK: Speed Sheet 오버레이
      if state.showSpeedSheet {
        Color.black.opacity(0.4)
          .ignoresSafeArea()
          .transition(.opacity)
          .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
              state.showSpeedSheet = false
            }
          }

        VStack {
          Spacer()
          PlaybackSpeedSheet(
            playbackSpeed: $vm.videoVM.playbackSpeed,
            onSpeedChange: { speed in
              vm.videoVM.setPlaybackSpeed(speed)
            }
          )
          .frame(width: 350, height: 180)
          .background(Color(.systemBackground))
          .clipShape(RoundedRectangle(cornerRadius: 16))
          .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
          .padding(.bottom, isDeviceLandscape ? 20 : 40)
          .transition(.move(edge: .bottom))
        }
      }
    }
    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: state.showSpeedSheet)
    .toolbarTitleDisplayMode(.inline)
    .toolbar {
      if !showFullScreen {
        ToolbarLeadingBackButton(icon: .chevron)
        ToolbarCenterTitle(text: videoTitle)
      }
    }
    .onAppear {
      lastSize = proxy.size
      updateOrientation()
    }
    .onChange(of: proxy.size) { oldSize, newSize in
      // 키보드는 높이만 변경하므로, 너비 변화만 체크 (회전 감지)
      let widthDiff = abs(newSize.width - lastSize.width)

      if widthDiff > 50 { // 너비가 50pt 이상 변하면 회전으로 간주
        lastSize = newSize
        updateOrientation()
      }
    }
  }

  private func updateOrientation() {
    isDeviceLandscape = proxy.size.width > proxy.size.height
  }
  // MARK: iPad 가로모드 레이아웃 스플릿 뷰
  @ViewBuilder
  private var landscapeView: some View {
    NavigationSplitView(columnVisibility: $columnVisibility) {
      ZStack {
//        Color.black.ignoresSafeArea(edges: .top, .bottom)

        VideoPlayerContainer(
          vm: vm,
          state: state,
          videoId: videoId,
          videoURL: videoURL,
          aspectRatio: nil,
          isLandscapeMode: true,
          showFeedbackPanel: true,
          onDrawingAction: onCaptureFrame,
          onFullscreenToggle: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
              showFullScreen.toggle()
            }
          },
          onToggleFeedbackPanel: {},
          onDragChanged: { value in
            state.dragOffset = value.translation.height
          },
          onDragEnded: { value in
            // iPad: 위로 드래그(-80 이하)하면 전체화면
            if !showFullScreen && value.translation.height < -80 {
              withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showFullScreen = true
              }
            }

            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
              state.dragOffset = 0
            }
          }
        )
        .offset(y: state.dragOffset * 0.5)
      }
      .ignoresSafeArea(.all, edges: .top)
      .navigationSplitViewColumnWidth(min: 600, ideal: 800, max: 1000)
    } detail: {
        FeedbackContainer(
          vm: vm,
          state: state,
          videoId: videoId,
          userId: userId,
          filteredFeedbacks: filteredFeedbacks,
          iPadLandscape: true,
          drawingImageNamespace: drawingImageNamespace,
          feedbackImageNamespace: feedbackImageNamespace,
          onDrawingAction: onCaptureFrame,
          editExistingDrawing: editExistingDrawing,
          onFeedbackSelect: nil,
          isSidebarVisible: columnVisibility == .all
        )
        .ignoresSafeArea(.all, edges: .top)
        .navigationSplitViewColumnWidth(min: 350, ideal: 450, max: 600)
    }
    .navigationSplitViewStyle(.balanced)
  }
  // MARK: - iPad 세로모드 레이아웃
  @ViewBuilder
  private var portraitView: some View {
      VStack(spacing: 0) {
        VideoPlayerContainer(
          vm: vm,
          state: state,
          videoId: videoId,
          videoURL: videoURL,
          aspectRatio: 16/9,
          isLandscapeMode: false,
          showFeedbackPanel: false,
          onDrawingAction: onCaptureFrame,
          onFullscreenToggle: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
              showFullScreen.toggle()
            }
          },
          onToggleFeedbackPanel: {},
          onDragChanged: { value in
            state.dragOffset = value.translation.height
          },
          onDragEnded: { value in
            // iPad: 위로 드래그(-80 이하)하면 전체화면
            if !showFullScreen && value.translation.height < -80 {
              withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showFullScreen = true
              }
            }

            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
              state.dragOffset = 0
            }
          }
        )
        .frame(height: proxy.size.width * 9 / 16)
        .offset(y: state.dragOffset * 0.5)

        FeedbackContainer(
          vm: vm,
          state: state,
          videoId: videoId,
          userId: userId,
          filteredFeedbacks: filteredFeedbacks,
          iPadLandscape: false,
          drawingImageNamespace: drawingImageNamespace,
          feedbackImageNamespace: feedbackImageNamespace,
          onDrawingAction: onCaptureFrame,
          editExistingDrawing: editExistingDrawing,
          onFeedbackSelect: nil
        )
      }
      .background(Color.backgroundNormal.ignoresSafeArea())
  }

  // MARK: - 전체화면 레이아웃
  @ViewBuilder
  private var fullScreenView: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      VideoPlayerContainer(
        vm: vm,
        state: state,
        videoId: videoId,
        videoURL: videoURL,
        aspectRatio: nil,
        isLandscapeMode: isDeviceLandscape,
        showFeedbackPanel: false,
        onDrawingAction: onCaptureFrame,
        onFullscreenToggle: {
          withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showFullScreen.toggle()
          }
        },
        onToggleFeedbackPanel: {},
        onDragChanged: { value in
          state.dragOffset = value.translation.height
        },
        onDragEnded: { value in
          // 전체화면에서 아래로 드래그(80 이상)하면 나가기
          if value.translation.height > 80 {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
              showFullScreen = false
            }
          }

          withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            state.dragOffset = 0
          }
        }
      )
      .offset(y: state.dragOffset * 0.5)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }
}

//#Preview {
//  iPadVideoView()
//}
