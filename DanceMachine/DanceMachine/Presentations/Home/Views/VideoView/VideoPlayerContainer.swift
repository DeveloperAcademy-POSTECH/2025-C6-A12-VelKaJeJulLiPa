//
//  VideoPlayerContainer.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/21/25.
//

import SwiftUI

/// 비디오 플레이어 + 컨트롤을 담당하는 컴포넌트 입니다.
struct VideoPlayerContainer: View {
  @Bindable var vm: VideoDetailViewModel
  @Bindable var state: VideoViewState
  
  let videoId: String
  let videoURL: String
  let aspectRatio: CGFloat?
  let isLandscapeMode: Bool
  let showFeedbackPanel: Bool
  let onDrawingAction: () -> Void
  let onFullscreenToggle: () -> Void
  let onToggleFeedbackPanel: () -> Void
  let onDragChanged: ((DragGesture.Value) -> Void)?
  let onDragEnded: ((DragGesture.Value) -> Void)?
  
  private var isIPad: Bool {
    UIDevice.current.userInterfaceIdiom == .pad
  }
  
  var body: some View {
    ZStack {
      // 비디오 플레이어
      if let player = vm.videoVM.player {
        VideoController(player: player)
          .aspectRatio(aspectRatio ?? 16/9, contentMode: .fit)
          .frame(
            maxWidth: isLandscapeMode ? .infinity : nil,
            maxHeight: isLandscapeMode ? .infinity : nil
          )
      } else {
        Color.black
          .aspectRatio(aspectRatio ?? 16/9, contentMode: .fit)
      }
      // 탭 영역
      GeometryReader { g in
        Color.clear
          .contentShape(Rectangle())
          .onTapGesture { location in
            self.handleTap(location: location, width: g.size.width)
          }
      }
      .gesture(
        DragGesture(minimumDistance: 30)
          .onChanged { value in
            // iPad: 양방향 모두 허용, iPhone: 방향별 제한
            if isIPad {
              onDragChanged?(value)
            } else {
              // iPhone: Landscape는 아래로만, Portrait는 위로만
              if isLandscapeMode {
                // 아래로 드래그 (양수)만 허용
                if value.translation.height > 0 {
                  onDragChanged?(value)
                }
              } else {
                // 위로 드래그 (음수)만 허용
                if value.translation.height < 0 {
                  onDragChanged?(value)
                }
              }
            }
          }
          .onEnded { value in
            // iPad: 양방향 모두 허용, iPhone: 방향별 제한
            if isIPad {
              onDragEnded?(value)
            } else {
              // iPhone: 같은 방향 체크
              if isLandscapeMode {
                if value.translation.height > 0 {
                  onDragEnded?(value)
                }
              } else {
                if value.translation.height < 0 {
                  onDragEnded?(value)
                }
              }
            }
          }
      )
      
      // 더블탭 Seek 인디케이터
      HStack(spacing: 0) {
        // 왼쪽 (뒤로가기)
        if vm.videoVM.showLeftSeekIndicator {
          DoubleTapSeekIndicator(
            isForward: false,
            tapCount: vm.videoVM.leftSeekCount
          )
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, isLandscapeMode ? 80 : 60)
        }

        Spacer()

        // 오른쪽 (앞으로가기)
        if vm.videoVM.showRightSeekIndicator {
          DoubleTapSeekIndicator(
            isForward: true,
            tapCount: vm.videoVM.rightSeekCount
          )
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, isLandscapeMode ? 80 : 60)
        }
      }
      .allowsHitTesting(false)
      
      // 비디오 오버레이 컨트롤
      if vm.videoVM.showControls {
        VideoControlOverlay(
          isDragging: $state.isDragging,
          sliderValue: $state.sliderValue,
          currentTime: vm.videoVM.currentTime,
          duration: vm.videoVM.duration,
          isPlaying: vm.videoVM.isPlaying,
          onSeek: { time in
            vm.videoVM.seekToTime(to: time)
          },
          onDragChanged: { time in
            state.sliderValue = time
            vm.videoVM.seekToTime(to: time)
          },
          onLeftAction: {
            vm.videoVM.seekToTime(to: vm.videoVM.currentTime - 5)
            if vm.videoVM.isPlaying {
              vm.videoVM.startAutoHideControls()
            }
          },
          onRightAction: {
            vm.videoVM.seekToTime(to: vm.videoVM.currentTime + 5)
            if vm.videoVM.isPlaying {
              vm.videoVM.startAutoHideControls()
            }
          },
          onCenterAction: {
            vm.videoVM.togglePlayPause()
          },
          onSpeedAction: {
            state.showSpeedSheet = true
          },
          onToggleOrientation: {
            // iPad는 onFullscreenToggle 사용, iPhone은 기존 방식
            if UIDevice.current.userInterfaceIdiom == .pad {
              onFullscreenToggle()
            } else {
              withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                state.forceShowLandscape.toggle()
                if state.forceShowLandscape {
                  state.enterLandscapeMode()
                } else {
                  state.exitLandscapeMode()
                }
              }
            }
          },
          onToggleFeedbackPanel: { onToggleFeedbackPanel() },
          isLandscapeMode: state.forceShowLandscape,
          showFeedbackPanel: showFeedbackPanel,
          drawingAction: onDrawingAction
        )
        .padding(.vertical, isIPad ? 40 : 0)
        .padding(.horizontal, isLandscapeMode && !showFeedbackPanel ? 24 : 0)
        .onChange(of: vm.videoVM.currentTime) { _, newValue in
          if !state.isDragging {
            state.sliderValue = newValue
          }
        }
        .onChange(of: state.isDragging) { _, newValue in
          if newValue {
            // 드래그 시작 시 자동 숨김 타이머 취소
            vm.videoVM.autoHideControlsTask?.cancel()
          } else {
            // 드래그 종료 시 자동 숨김 타이머 재시작
            if vm.videoVM.isPlaying {
              vm.videoVM.startAutoHideControls()
            }
          }
        }
        .transition(.opacity)
        .zIndex(10)
      }
    }
    .overlay(alignment: .center) {
      if vm.videoVM.showDownloadError {
        VideoDownloadError {
          Task {
            await vm.videoVM.retryDownload(
              from: videoURL,
              videoId: videoId
            )
          }
        }
      } else if vm.videoVM.isLoading {
        ZStack {
          Color.backgroundElevated
          if vm.videoVM.isDownloading {
            downloadProgress(progress: vm.videoVM.loadingProgress)
          } else {
            VideoLottieView()
          }
        }
      }
    }
  }
  
  private func handleTap(location: CGPoint, width: CGFloat) {
    if location.x < width / 3 {
      vm.videoVM.leftTab()
    } else if location.x > width * 2 / 3 {
      vm.videoVM.rightTap()
    } else {
      vm.videoVM.centerTap()
    }
  }
}

//#Preview {
//  VideoPlayerContainer()
//}
