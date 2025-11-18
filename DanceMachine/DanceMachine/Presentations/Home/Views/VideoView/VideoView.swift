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

  @State private var showFeedbackInput: Bool = false
  @State private var feedbackType: FeedbackType = .point
  @State private var feedbackFilter: FeedbackFilter = .all

  // MARK: 슬라이더 관련
  @State private var isDragging: Bool = false
  @State private var sliderValue: Double = 0

  // MARK: 피드백 시점 관련
  @State private var pointTime: Double = 0
  @State private var intervalTime: Double = 0

  // MARK: 글래스 이팩트 버튼
  @Namespace private var buttonNamespace
  @State private var showIntervalButton: Bool = false
  @State private var buttonSpacing: CGFloat = 4

  
  // MARK: 가로모드 관련
  @State private var isLandscape: Bool = false // 디바이스 가로모드 감지
  @State private var forceShowLandscape: Bool = false // 전체 화면 버튼으로 가는 가로모드
  @State private var showFeedbackPanel: Bool = false

  // MARK: 스와이프 제스처 관련
  @State private var dragOffset: CGFloat = 0
  
  // MARK: 배속 좆러
  @State private var showSpeedSheet: Bool = false
  
  // MARK: 스크롤 관련
  @State private var scrollProxy: ScrollViewProxy? = nil
  
  // MARK: 신고하기 관련
//  @State private var reportTargetFeedback: Feedback? = nil
  @State private var showCreateReportSuccessToast: Bool = false
  
  // MARK: 이미지 캡쳐 결과 //
  @State private var showFeedbackPaperDrawingView: Bool = false
  @State private var capturedImage: UIImage? = nil
  @State private var editedOverlayImage: UIImage? = nil
  
  // 🔥 전체 화면 프리뷰용 상태 & 네임스페이스 //
  @Namespace private var drawingImageNamespace
  @State private var showDrawingImageFull: Bool = false
  
  // 🔥 피드백 카드 이미지 풀스크린용 상태
  @Namespace private var feedbackImageNamespace
  @State private var selectedFeedbackImageURL: String? = nil
  @State private var showFeedbackImageFull: Bool = false
  
  // MARK: 전역으로 관리되는 ID
  let userId: String = FirebaseAuthManager.shared.userInfo?.userId ?? ""
  
  let videoId: String
  let videoTitle: String
  let videoURL: String
  let teamspaceId: String

  
  // 피드백 필터링 (내 피드백, 전체 피드백)
  var filteredFeedbacks: [Feedback] {
    switch feedbackFilter {
    case .all: return vm.feedbackVM.feedbacks
    case .mine: return vm.feedbackVM.feedbacks.filter { $0.taggedUserIds.contains(userId) }
    }
  }
  
  /// 이미지 확대 변수
  private var isImageOverlayPresented: Bool {
    showDrawingImageFull || showFeedbackImageFull
  }
  
  var body: some View {
    GeometryReader { proxy in
      Group {
        if vm.forceShowLandscape {
          LandscapeView(
            vm: vm,
            isDragging: $isDragging,
            sliderValue: $sliderValue,
            feedbackFilter: $feedbackFilter,
            scrollProxy: $scrollProxy,
            pointTime: $pointTime,
            intervalTime: $intervalTime,
            dragOffset: $dragOffset,
            forceShowLandscape: $forceShowLandscape,
            filteredFeedback: filteredFeedbacks,
            userId: userId,
            proxy: proxy,
            videoId: videoId,
            showFeedbackPaperDrawingView: $showFeedbackPaperDrawingView,
            capturedImage: $capturedImage,
            editedOverlayImage: $editedOverlayImage,
            drawingImageNamespace: drawingImageNamespace,
            showDrawingImageFull: $showDrawingImageFull,
            feedbackImageNamespace: feedbackImageNamespace,
            selectedFeedbackImageURL: $selectedFeedbackImageURL,
            showFeedbackImageFull: $showFeedbackImageFull
          )
        } else {
          ZStack {
            Color.backgroundNormal.ignoresSafeArea()
            VStack {
              PortraitView(
                vm: vm,
                isDragging: $isDragging,
                sliderValue: $sliderValue,
                feedbackFilter: $feedbackFilter,
                scrollProxy: $scrollProxy,
                pointTime: $pointTime,
                intervalTime: $intervalTime,
                showFeedbackInput: $showFeedbackInput,
                dragOffset: $dragOffset,
                forceShowLandscape: $forceShowLandscape,
                filteredFeedback: filteredFeedbacks,
                userId: userId,
                proxy: proxy,
                videoTitle: videoTitle,
                videoId: videoId,
                showFeedbackPaperDrawingView: $showFeedbackPaperDrawingView,
                capturedImage: $capturedImage,
                editedOverlayImage: $editedOverlayImage,
                drawingImageNamespace: drawingImageNamespace,
                showDrawingImageFull: $showDrawingImageFull,
                feedbackImageNamespace: feedbackImageNamespace,
                selectedFeedbackImageURL: $selectedFeedbackImageURL,
                showFeedbackImageFull: $showFeedbackImageFull
              )
            }
          }
        }
        
        // 드로잉 이미지 전체 프리뷰
        if let image = editedOverlayImage {
          ZoomableImageOverlay(
            isPresented: $showDrawingImageFull,
            backgroundColor: Color.backgroundNormal
          ) {
            Image(uiImage: image)
              .resizable()
              .scaledToFit()
              .matchedGeometryEffect(id: "feedbackImage", in: drawingImageNamespace)
          }
        }
        
        // 피드백 카드 이미지 전체 프리뷰
        if let urlString = selectedFeedbackImageURL,
           let url = URL(string: urlString) {
          ZoomableImageOverlay(
            isPresented: $showFeedbackImageFull,
            backgroundColor: Color.backgroundNormal
          ) {
            KFImage(url)
              .placeholder {
                ProgressView()
              }
              .retry(maxCount: 2, interval: .seconds(2))
              .cacheOriginalImage()
              .resizable()
              .scaledToFit()
              .matchedGeometryEffect(id: urlString, in: feedbackImageNamespace)
          }
        }
      }
      .onChange(of: showFeedbackInput) { _, newValue in
        if !newValue {
          vm.feedbackVM.isRecordingInterval = false
          self.editedOverlayImage = nil // 인풋 뷰가 내려갈 때 이미지도 초기화
        }
      }
      .toolbar(.hidden, for: .tabBar)
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
    .onChange(of: isImageOverlayPresented) { dismissKeyboard() } // 오버레이(이미지 확대)로 교체시 키보드 내리기
    // 드로잉 이미지 확대 시, 툴 바 숨기기 처리
    .toolbar(
      showDrawingImageFull || showFeedbackImageFull || vm.forceShowLandscape ? .hidden : .visible,
      for: .navigationBar
    )
    .fullScreenCover(isPresented: $showFeedbackPaperDrawingView) {
      // MARK: - iOS 18 / 26 분기 처리 (Drawing)
      if #available(iOS 26.0, *) {
        FeedbackPaperDrawingView(image: $capturedImage) { image in
          editedOverlayImage = image
          self.capturedImage = nil
        }
      }
      else {
        FeedbackPencilDrawingView(image: $capturedImage,
          onDone: { merged in
          DispatchQueue.main.async {
            editedOverlayImage = merged
            self.capturedImage = nil
            showFeedbackPaperDrawingView = false
          }
        },
          onCancel: {
          DispatchQueue.main.async {
            self.capturedImage = nil
            showFeedbackPaperDrawingView = false
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
      bottomPadding: 63, // FIXME: 신고하기 - 하단 공백 조정 필요
      content: {
        ToastView(text: "신고가 접수되었습니다.\n조치사항은 이메일로 안내해드리겠습니다.", icon: .check)
      }
    )
    .alert(
      "영상 정보가 없어용~",
      isPresented: $vm.videoVM.notiFalseAlert,
      actions: {
        Button("나가기", role: .destructive) { router.pop() }
      },
      message: {
        Text("ㅅㄱ")
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

