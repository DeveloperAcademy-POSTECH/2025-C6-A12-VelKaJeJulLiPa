//
//  PortraitView.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/16/25.
//

import SwiftUI
import AVFoundation

struct PortraitView: View {
  @Bindable var vm: VideoDetailViewModel
  
  @Binding var isDragging: Bool
  @Binding var sliderValue: Double
  
  @Binding var feedbackFilter: FeedbackFilter
  @Binding var scrollProxy: ScrollViewProxy?
  
  @Binding var pointTime: Double
  @Binding var intervalTime: Double
  
  @Binding var showFeedbackInput: Bool
  
  @Binding var dragOffset: CGFloat
  @Binding var forceShowLandscape: Bool
  
  @State private var showSpeedSheet: Bool = false
  
  @State private var feedbackType: FeedbackType = .point
  
  let filteredFeedback: [Feedback]
  let userId: String
  let proxy: GeometryProxy
  let videoTitle: String
  let videoId: String
  
  /// =================================================
  /// 드로잉 관련
  // MARK: 이미지 캡쳐 결과 //
  @Binding var showFeedbackPaperDrawingView: Bool
  @Binding var capturedImage: UIImage?
  @Binding var editedOverlayImage: UIImage?
  
  let drawingImageNamespace: Namespace.ID
  @Binding var showDrawingImageFull: Bool

  let feedbackImageNamespace: Namespace.ID
  @Binding var selectedFeedbackImageURL: String?
  @Binding var showFeedbackImageFull: Bool
  
  /// 이미지 확대 변수
  private var isImageOverlayPresented: Bool {
    showDrawingImageFull || showFeedbackImageFull
  }
  /// ==================================================
  
  var body: some View {
    VStack(spacing: 0) {
      ZStack {
        if let player = vm.videoVM.player {
          VideoController(player: player)
            .aspectRatio(16/9, contentMode: .fit)
        } else {
          Color.black
            .aspectRatio(16/9, contentMode: .fit)
        }
        
        // 탭 영역
        GeometryReader { tapProxy in
          Color.clear
            .contentShape(Rectangle())
            .onTapGesture { location in
              let tapWidth = tapProxy.size.width
              if location.x < tapWidth / 3 {
                vm.videoVM.leftTab()
              } else if location.x > tapWidth * 2 / 3 {
                vm.videoVM.rightTap()
              } else {
                vm.videoVM.centerTap()
              }
            }
        }
        
        // 더블탭 Seek 인디케이터
        HStack(spacing: 0) {
          // 왼쪽 (뒤로가기)
          if vm.videoVM.showLeftSeekIndicator {
            DoubleTapSeekIndicator(
              isForward: false,
              tapCount: vm.videoVM.leftSeekCount
            )
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.leading, 60)
          }

          Spacer()

          // 오른쪽 (앞으로가기)
          if vm.videoVM.showRightSeekIndicator {
            DoubleTapSeekIndicator(
              isForward: true,
              tapCount: vm.videoVM.rightSeekCount
            )
              .frame(maxWidth: .infinity, alignment: .trailing)
              .padding(.trailing, 60)
          }
        }
        .allowsHitTesting(false)

        
        if vm.videoVM.showControls {
          VideoControlOverlay(
            isDragging: $isDragging,
            sliderValue: $sliderValue,
            currentTime: vm.videoVM.currentTime,
            duration: vm.videoVM.duration,
            isPlaying: vm.videoVM.isPlaying,
            onSeek: { time in
              vm.videoVM.seekToTime(to: time)
            },
            onDragChanged: { time in
              self.sliderValue = time
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
              self.showSpeedSheet = true
            },
            onToggleOrientation: {
              withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                vm.forceShowLandscape.toggle()
                if vm.forceShowLandscape {
                  vm.enterLandscapeMode()
                } else {
                  vm.exitLandscapeMode()
                }
              }
            },
            onToggleFeedbackPanel: { },
            isLandscapeMode: vm.forceShowLandscape,
            showFeedbackPanel: false
          )
          .onChange(of: vm.videoVM.currentTime) { _, newValue in
            if !isDragging {
              sliderValue = newValue
            }
          }
          .transition(.opacity)
          .zIndex(10)
        }
      }
      .frame(height: proxy.size.width * 9 / 16)
      .offset(y: dragOffset * 0.5) // 드래그 방향으로 영상 이동 (50% 감쇠)
      .gesture(
        DragGesture()
          .onChanged { value in
            // 위로 드래그할 때만 반응 (음수 값)
            if value.translation.height < 0 {
              dragOffset = value.translation.height
            }
          }
          .onEnded { value in
            // 위로 80 이상 드래그하면 전체화면으로 전환
            if value.translation.height < -80 {
              withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                forceShowLandscape = true
                vm.enterLandscapeMode()
              }
            }
            // 드래그 취소 시 원위치로
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
              dragOffset = 0
            }
          }
      )
      .overlay {
        if vm.videoVM.isLoading {
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
      
      VStack(spacing: 0) {
        FeedbackSection(feedbackFilter: $feedbackFilter)
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
        Divider()
        FeedbackListView(
          vm: vm,
          pointTime: $pointTime,
          intervalTime: $intervalTime,
          scrollProxy: $scrollProxy,
          filteredFeedbacks: filteredFeedback,
          userId: userId,
          videoId: videoId,
          imageNamespace: drawingImageNamespace,
          selectedFeedbackImageURL: $selectedFeedbackImageURL,
          showFeedbackImageFull: $showFeedbackImageFull
        )
      }
      .ignoresSafeArea(.keyboard)
      .contentShape(Rectangle())
      .onTapGesture {
        if showFeedbackInput {
          showFeedbackInput = false
          dismissKeyboard()
        }
      }
    }
    .safeAreaInset(edge: .bottom) {
      if vm.forceShowLandscape || isImageOverlayPresented {
        EmptyView()
      } else {
        Group {
          if showFeedbackInput {
            /// FeedbackInPutView 여기
            FeedbackInPutView(
              teamMembers: vm.teamMembers,
              feedbackType: feedbackType,
              currentTime: pointTime,
              startTime: intervalTime,
              onSubmit: { content, taggedUserId in
                Task {
                  // MARK: - 구간 피드백
                  if feedbackType == .point {
                    await vm.feedbackVM.createPointFeedback(
                      videoId: videoId,
                      authorId: userId,
                      content: content,
                      taggedUserIds: taggedUserId,
                      atTime: pointTime,
                      image: self.editedOverlayImage
                    )
                  } else { // 시점 피드백
                    await vm.feedbackVM.createIntervalFeedback(
                      videoId: videoId,
                      authorId: userId,
                      content: content,
                      taggedUserIds: taggedUserId,
                      startTime: vm.feedbackVM.intervalStartTime ?? 0,
                      endTime: vm.videoVM.currentTime,
                      image: self.editedOverlayImage
                    )
                  }
                  showFeedbackInput = false
                  
                  // 피드백 제출 후 스크롤 최상단 이동
                  DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                      scrollProxy?.scrollTo("topFeedback", anchor: .top)
                    }
                  }
                }
              },
              refresh: {
                self.showFeedbackInput = false
                dismissKeyboard()
              },
              timeSeek: { vm.videoVM.seekToTime(to: self.pointTime) },
              drawingButtonTapped: { captureCurrentFrame() },
              feedbackDrawingImage: $editedOverlayImage,
              imageNamespace: drawingImageNamespace,
              showImageFull: $showDrawingImageFull
            )
          } else {
            FeedbackButtons(
              landScape: false,
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
    }
    .toolbarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarLeadingBackButton(icon: .chevron)
      ToolbarCenterTitle(text: videoTitle)
    }
  }
  
  /// 현재 플레이어 시점의 프레임을 이미지로 캡처 (copyCGImage 대체)
  private func captureCurrentFrame() {
    guard let player = vm.videoVM.player,
          let asset  = player.currentItem?.asset else { return }
    
    let time = player.currentTime()
    
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    generator.requestedTimeToleranceBefore = .zero
    generator.requestedTimeToleranceAfter  = .zero
    generator.dynamicRangePolicy = .forceSDR
    
    generator.generateCGImageAsynchronously(for: time) { cgImage, actualTime, error in
      guard let cgImage = cgImage, error == nil else {
        // print("error: \(error ?? NSError()")
        print("적절한 에러 처리 추가하기")
        return
      }
      let image = UIImage(cgImage: cgImage)
      DispatchQueue.main.async {
        self.capturedImage = image
        self.showFeedbackPaperDrawingView = true
        print("이미지 캡처 성공 @ \(CMTimeGetSeconds(actualTime))s")
      }
    }
  }
}

//#Preview {
//  PortraitView()
//}
