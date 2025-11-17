//
//  LandscapeView.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/16/25.
//

import SwiftUI
import AVFoundation

struct LandscapeView: View {
  @Bindable var vm: VideoDetailViewModel
  
  @Binding var isDragging: Bool
  @Binding var sliderValue: Double
  
  @State private var showSpeedModal: Bool = false

  @State private var showFeedbackPanel: Bool = false
  @State private var selectedFeedbackForReply: Feedback? = nil

  @State private var feedbackType: FeedbackType = .point
  @State private var showFeedbackInput: Bool = false

  @State private var showReplyInputView: Bool = false
  
  @Binding var feedbackFilter: FeedbackFilter
  @Binding var scrollProxy: ScrollViewProxy?
  
  @Binding var pointTime: Double
  @Binding var intervalTime: Double
  
  @Binding var dragOffset: CGFloat
  @Binding var forceShowLandscape: Bool
  
  let filteredFeedback: [Feedback]
  let userId: String
  let proxy: GeometryProxy
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
    ZStack(alignment: .bottom) {
      HStack(spacing: 0) {
        // MARK: 비디오 + 컨트롤 영역
        ZStack {
          Color.black

          // 비디오
          if let player = vm.videoVM.player {
            VideoController(player: player)
              .aspectRatio(16/9, contentMode: .fit)
              .frame(maxWidth: .infinity, maxHeight: .infinity)
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
          .gesture(
            DragGesture(minimumDistance: 30)
              .onChanged { value in
                // 아래로 드래그할 때만 반응 (양수 값)
                if value.translation.height > 0 {
                  dragOffset = value.translation.height
                }
              }
              .onEnded { value in
                // 아래로 80 이상 드래그하면 세로모드로 전환
                if value.translation.height > 80 {
                  withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    forceShowLandscape = false
                    vm.exitLandscapeMode()
                  }
                }
                // 드래그 취소 시 원위치로
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                  dragOffset = 0
                }
              }
          )
          
          HStack(spacing: 0) {
            // 왼쪽 (뒤로가기)
            if vm.videoVM.showLeftSeekIndicator {
              DoubleTapSeekIndicator(
                isForward: false,
                tapCount: vm.videoVM.leftSeekCount
              )
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 80)
            }

            Spacer()

            // 오른쪽 (앞으로가기)
            if vm.videoVM.showRightSeekIndicator {
              DoubleTapSeekIndicator(
                isForward: true,
                tapCount: vm.videoVM.rightSeekCount
              )
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 80)
            }
          }
          .allowsHitTesting(false)
        }
        .frame(width: showFeedbackPanel ? proxy.size.width * 0.6 : nil)
        .offset(y: showFeedbackPanel ? 0 : dragOffset * 0.5)
        .clipped()
        .overlay {
          // 컨트롤
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
                self.showSpeedModal = true
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
              onToggleFeedbackPanel: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                  showFeedbackPanel.toggle()
                }
              },
              isLandscapeMode: vm.forceShowLandscape,
              showFeedbackPanel: showFeedbackPanel
            )
            .onChange(of: vm.videoVM.currentTime) { _, newValue in
              if !isDragging {
                sliderValue = newValue
              }
            }
            .padding(.horizontal, showFeedbackPanel ? 0 : 44)
            .transition(.opacity)
          }
        }
        
        // MARK: 피드백 패널
        if showFeedbackPanel {
          RoundedRectangle(cornerRadius: 8)
            .fill(.backgroundNormal)
            .frame(width: proxy.size.width * 0.4)
            .overlay {
              ZStack {
                // 피드백 리스트 패널
                if selectedFeedbackForReply == nil {
                  LandscapeFeedbackPanel(
                    vm: vm,
                    feedbackFilter: $feedbackFilter,
                    pointTime: $pointTime,
                    intervalTime: $intervalTime,
                    showFeedbackInput: $showFeedbackInput,
                    scrollProxy: $scrollProxy,
                    feedbackType: $feedbackType,
                    filteredFeedback: filteredFeedback,
                    userId: userId,
                    videoId: videoId,
                    imageNamespace: feedbackImageNamespace,
                    selectedFeedbackImageURL: $selectedFeedbackImageURL,
                    showFeedbackImageFull: $showFeedbackImageFull,
                    onFeedbackSelect: { feedback in
                      withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedFeedbackForReply = feedback
                      }
                    },
                    onClose: {
                      withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showFeedbackPanel = false
                      }
                    }
                  )
                  .opacity(selectedFeedbackForReply == nil ? 1 : 0)
                  .offset(x: selectedFeedbackForReply == nil ? 0 : -20)
                }

                // 답글 패널
                if let feedback = selectedFeedbackForReply {
                  LandscapeReplyPanel(
                    vm: vm,
                    feedback: feedback,
                    pointTime: $pointTime,
                    intervalTime: $intervalTime,
                    userId: userId,
                    imageNamespace: feedbackImageNamespace,
                    selectedFeedbackImageURL: $selectedFeedbackImageURL,
                    showFeedbackImageFull: $showFeedbackImageFull,
                    showInputView: $showReplyInputView,
                    onBack: {
                      withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedFeedbackForReply = nil
                        self.showReplyInputView = false
                      }
                    },
                    onClose: {
                      withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedFeedbackForReply = nil
                        self.showReplyInputView = false
                      }
                    }
                  )
                  .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                  ))
                }
              }
              .clipped()
            }
            .transition(.move(edge: .trailing))
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .ignoresSafeArea()
      
      // MARK: Speed Sheet 오버레이
      if showSpeedModal {
        Color.black.opacity(0.7)
          .ignoresSafeArea()
          .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
              self.showSpeedModal = false
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
        .offset(y: -40)
        .transition(.scale.combined(with: .opacity))
      }
    }
    .safeAreaInset(edge: .bottom) {
      Group {
        if let feedback = selectedFeedbackForReply,
           self.showReplyInputView {
          // Reply 입력 (ReplyRecycle)
          ReplyRecycle(
            teamMembers: vm.teamMembers,
            replyingTo: vm.getAuthorUser(for: feedback.authorId),
            onSubmit: { content, taggedIds in
              Task {
                await vm.feedbackVM.addReply(
                  to: feedback.feedbackId.uuidString,
                  authorId: userId,
                  content: content,
                  taggedUserIds: taggedIds
                )
                self.showReplyInputView = false
              }
            },
            refresh: {
              dismissKeyboard()
              self.showReplyInputView = false
            }
          )
        } else if showFeedbackInput {
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
              self.vm.feedbackVM.isRecordingInterval = false
              dismissKeyboard()
            },
            timeSeek: { vm.videoVM.seekToTime(to: self.pointTime) },
            drawingButtonTapped: { captureCurrentFrame() },
            feedbackDrawingImage: $editedOverlayImage,
            imageNamespace: drawingImageNamespace,
            showImageFull: $showDrawingImageFull
          )
        }
      }
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
//  LandscapeView()
//}
