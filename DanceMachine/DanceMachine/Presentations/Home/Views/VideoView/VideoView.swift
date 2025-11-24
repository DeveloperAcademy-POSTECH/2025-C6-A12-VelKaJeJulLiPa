//
//  VideoView.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/3/25.
//

import SwiftUI
import AVKit
import Kingfisher

struct VideoView: View {
  @EnvironmentObject private var router: MainRouter
  
  @State private var vm: VideoDetailViewModel = .init()
  @State private var state: VideoViewState = .init()
  
  // MARK: 신고하기 관련
  @State private var showCreateReportSuccessToast: Bool = false
  @State var drawingPause: Bool = false
  
  // 🔥 전체 화면 프리뷰용 상태 & 네임스페이스 //
  @Namespace private var drawingImageNamespace
  
  // 🔥 피드백 카드 이미지 풀스크린용 상태
  @Namespace private var feedbackImageNamespace
  
  
  // MARK: 전역으로 관리되는 ID
  let userId: String = FirebaseAuthManager.shared.userInfo?.userId ?? ""
  
  let videoId: String
  let videoTitle: String
  let videoURL: String
  let teamspaceId: String

  // 피드백 필터링 (내 피드백, 전체 피드백)
  var filteredFeedbacks: [Feedback] {
    switch state.feedbackFilter {
    case .all: return vm.feedbackVM.feedbacks
    case .mine: return vm.feedbackVM.feedbacks.filter { $0.taggedUserIds.contains(userId) }
    }
  }
  
  var body: some View {
    GeometryReader { proxy in
      ZStack {
        deviceSpecificView(proxy: proxy)
          .onChange(of: state.showFeedbackInput) { _, newValue in
            // 피드백 입력창이 닫힐 때 모든 드로잉 관련 데이터 초기화
            if !newValue {
              vm.feedbackVM.isRecordingInterval = false
              state.editedOverlayImage = nil // 합성된 이미지 초기화
              state.savedDrawingData = nil // PencilKit 데이터 초기화
              state.savedMarkupData = nil // PaperKit 데이터 초기화
              state.backgroundImage = nil // 원본 캡처 이미지 초기화
              state.isEditingExistingDrawing = false // 편집 모드 초기화
            }
          }
        
        if let urlString = state.selectedFeedbackImageURL,
           let url = URL(string: urlString) {
          ZoomableImageOverlay(
            isPresented: $state.showFeedbackImageFull,
            backgroundColor: Color.black) {
              KFImage(url)
                .placeholder {
                  VideoLottieView()
                }
                .retry(maxCount: 2, interval: .seconds(2))
                .cacheOriginalImage()
                .resizable()
                .aspectRatio(contentMode: .fit)
                .matchedGeometryEffect(id: urlString, in: feedbackImageNamespace)
            }
        }
      }
    }
    
    .disabled(vm.feedbackVM.isUploading)
    .overlay(alignment: .center, content: {
      if vm.feedbackVM.isUploading {
        ZStack {
          Color.black.opacity(0.5)
            .ignoresSafeArea()
          VideoLottieView()
        }
      }
    })
    .onChange(of: state.isImageOverlayPresented) { dismissKeyboard() } // 오버레이(이미지 확대)로 교체시 키보드 내리기
    // 드로잉 이미지 확대 시, 툴 바 숨기기 처리
    .toolbar(
      state.showDrawingImageFull || state.showFeedbackImageFull || state.forceShowLandscape ? .hidden : .visible,
      for: .navigationBar
    )
    .fullScreenCover(isPresented: $state.showFeedbackPaperDrawingView) {
      // MARK: - iOS 18 / 26 분기 처리 (Drawing)
      if #available(iOS 26.0, *) {
        FeedbackPaperDrawingView(
          image: $state.capturedImage,
          drawingPause: $drawingPause,
          onComplete: { finalImage, markupData in
            // 완료 시: 합성 이미지 + 마크업 데이터 저장
            state.editedOverlayImage = finalImage // 배경 + 드로잉 합성 이미지
            state.savedMarkupData = markupData // 수정 가능한 마크업 데이터
            state.backgroundImage = state.capturedImage // 원본 배경 이미지 (재수정 시 사용)
            state.capturedImage = nil
            state.isEditingExistingDrawing = false

            // 피드백 입력 상태가 아니면 자동으로 피드백 입력창 열기
            if !state.showFeedbackInput {
              state.feedbackType = .point
              state.pointTime = vm.videoVM.currentTime
              state.showFeedbackInput = true
              if vm.videoVM.isPlaying {
                vm.videoVM.togglePlayPause()
              }

              // 가로모드일 때 피드백 패널이 안 열려있으면 열기
              if state.forceShowLandscape && !state.showFeedbackPanel {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                  state.showFeedbackPanel = true
                }
              }

              // iPad 전체화면일 때 전체화면 나가기
              if UIDevice.current.userInterfaceIdiom == .pad && state.iPadShowFullScreen {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                  state.iPadShowFullScreen = false
                }
              }
            }
          },
          initialMarkupData: state.isEditingExistingDrawing ? state.savedMarkupData : nil // 편집 모드면 기존 데이터 로드
        )
      }
      else {
        FeedbackPencilDrawingView(
          image: $state.capturedImage,
          drawingPause: $drawingPause,
          initialDrawing: state.isEditingExistingDrawing ? state.savedDrawingData : nil,
          // 편집 모드면 기존 데이터 로드
          onDone: { merged, drawingData in
            DispatchQueue.main.async {
              // 완료 시: 합성 이미지 + 드로잉 데이터 저장
              state.editedOverlayImage = merged // 배경 + 드로잉 합성 이미지
              state.savedDrawingData = drawingData // 수정 가능한 드로잉 데이터
              state.backgroundImage = state.capturedImage // 원본 배경 이미지 (재수정 시 사용)
              state.capturedImage = nil
              state.isEditingExistingDrawing = false
              state.showFeedbackPaperDrawingView = false

              // 피드백 입력 상태가 아니면 자동으로 피드백 입력창 열기
              if !state.showFeedbackInput {
                state.feedbackType = .point
                state.pointTime = vm.videoVM.currentTime
                state.showFeedbackInput = true
                if vm.videoVM.isPlaying {
                  vm.videoVM.togglePlayPause()
                }

                // 가로모드일 때 피드백 패널이 안 열려있으면 열기
                if state.forceShowLandscape && !state.showFeedbackPanel {
                  withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    state.showFeedbackPanel = true
                  }
                }

                // iPad 전체화면일 때 전체화면 나가기
                if UIDevice.current.userInterfaceIdiom == .pad && state.iPadShowFullScreen {
                  withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    state.iPadShowFullScreen = false
                  }
                }
              }
            }
          },
          onCancel: {
            DispatchQueue.main.async {
              state.resetDrwaingData()
            }
          }
        )
      }
    }
    .task {
      await self.vm.loadAllData(
        videoId: videoId,
        videoURL: videoURL,
        teamspaceId: teamspaceId
      )
    }
    .onDisappear {
      vm.videoVM.cleanPlayer()
    }
    .toast(
      isPresented: $showCreateReportSuccessToast,
      duration: 3,
      position: .bottom,
      bottomPadding: 16, // FIXME: 신고하기 - 하단 공백 조정 필요
      content: {
        ToastView(text: "신고가 접수되었습니다.\n조치사항은 이메일로 안내해드리겠습니다.", icon: .check)
      }
    )
    .alert(
      vm.errorMsg,
      isPresented: $vm.showMemberError,
      actions: {
        Button("재시도", role: .destructive) {
          Task {
            await vm.loadAllData(videoId: videoId, videoURL: videoURL, teamspaceId: teamspaceId)
          }
        }
      }
    )
    .alert(
      "존재하지 않는 영상입니다.",
      isPresented: $vm.videoVM.notiFalseAlert,
      actions: {
        Button("확인", role: .destructive) { router.pop() }
      }
    )
    // MARK: 신고 완료 토스트 리시버
    .onReceive(NotificationCenter.publisher(for: .toast(.reportSuccess))) { notification in
      if let toastViewName = notification.userInfo?["toastViewName"] as? ReportToastReceiveViewType,
         toastViewName == .videoView {
        showCreateReportSuccessToast = true
      }
    }
    // MARK: 사용자가 영상 화면을 보고 있는데, 푸시 알림으로 화면 접근하려 할 때 영상 정보 업데이트
    .onReceive(NotificationCenter.publisher(for: .video(.refreshView))) { notification in
        guard let videoId = notification.userInfo?["videoId"] as? String,
              let videoURL = notification.userInfo?["videoURL"] as? String,
              let teamspaceId = notification.userInfo?["teamspaceId"] as? String else { return }

        Task {
            await vm.loadAllData(videoId: videoId, videoURL: videoURL, teamspaceId: teamspaceId)
        }
    }
  }
  
  /// 기기별 뷰 함수입니당
  @ViewBuilder
  private func deviceSpecificView(proxy: GeometryProxy) -> some View {
    if UIDevice.current.userInterfaceIdiom == .pad {
      // iPad
      iPadVideoView(
        vm: vm,
        state: state,
        videoId: videoId,
        videoTitle: videoTitle,
        videoURL: videoURL,
        userId: userId,
        filteredFeedbacks: filteredFeedbacks,
        proxy: proxy,
        drawingImageNamespace: drawingImageNamespace,
        feedbackImageNamespace: feedbackImageNamespace,
        onCaptureFrame: { self.captureCurrentFrame() },
        editExistingDrawing: { self.editExistingDrawing() },
        drawingPause: $drawingPause
      )
    } else {
      // iPhone
      if state.forceShowLandscape {
        iPhoneLandscapeView(
          vm: vm,
          state: state,
          drawingPause: $drawingPause,
          filteredFeedback: filteredFeedbacks,
          userId: userId,
          proxy: proxy,
          videoId: videoId,
          videoURL: videoURL,
          onCaptureFrame: { self.captureCurrentFrame()
          },
          editExistingDrawing: { self.editExistingDrawing() },
          drawingImageNamespace: drawingImageNamespace,
          feedbackImageNamespace: feedbackImageNamespace
        )
      } else {
        iPhonePortraitView(
          vm: vm,
          state: state,
          drawingPause: $drawingPause,
          filteredFeedback: filteredFeedbacks,
          userId: userId,
          proxy: proxy,
          videoTitle: videoTitle,
          videoId: videoId,
          videoURL: videoURL,
          drawingImageNamespace: drawingImageNamespace,
          feedbackImageNamespace: feedbackImageNamespace,
          onCaptureFrame: { self.captureCurrentFrame()
          },
          editExistingDrawing: { self.editExistingDrawing() }
        )
      }
    }
  }
  
  // MARK: - 드로잉 관련 함수

  /// "드로잉 하기" 버튼 클릭 시: 현재 비디오 프레임을 캡처하여 드로잉 시작
  /// - 비디오의 현재 재생 시점을 이미지로 캡처
  /// - 캡처한 이미지를 배경으로 드로잉 뷰 표시
  /// - isEditingExistingDrawing = false (새 드로잉 모드)
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
        print("적절한 에러 처리 추가하기")
        return
      }
      let image = UIImage(cgImage: cgImage)
      DispatchQueue.main.async {
        state.capturedImage = image // 드로잉 뷰에 전달할 이미지
        state.backgroundImage = image // 재수정 시 사용할 원본 이미지 저장
        state.isEditingExistingDrawing = false // 새 드로잉 모드
        state.showFeedbackPaperDrawingView = true
        print("이미지 캡처 성공 @ \(CMTimeGetSeconds(actualTime))s")
      }
    }
  }

  /// 썸네일 클릭 시: 기존 드로잉을 수정 모드로 열기
  /// - 원본 배경 이미지 (backgroundImage)를 다시 로드
  /// - 저장된 드로잉 데이터 (savedMarkupData/savedDrawingData)를 로드
  /// - isEditingExistingDrawing = true (편집 모드)
  private func editExistingDrawing() {
    guard let backgroundImage = state.backgroundImage else { return }

    state.capturedImage = backgroundImage // 원본 배경 이미지 재로드
    state.isEditingExistingDrawing = true // 편집 모드 활성화
    state.showFeedbackPaperDrawingView = true
  }
}

#Preview {
  NavigationStack {
    VideoView(
      videoId: "3",
      videoTitle: "벨코의 리치맨",
      videoURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
      teamspaceId: ""
    )
  }
  .environmentObject(MainRouter())
  .preferredColorScheme(.dark)
}

