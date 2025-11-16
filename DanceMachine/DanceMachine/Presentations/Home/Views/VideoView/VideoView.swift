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
  let teamspaceId = FirebaseAuthManager.shared.currentTeamspace?.teamspaceId
  let userId = FirebaseAuthManager.shared.userInfo?.userId ?? ""
  
  
  let videoId: String
  let videoTitle: String
  let videoURL: String
  
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
//    .safeAreaInset(edge: .bottom) {
//      if vm.forceShowLandscape || isImageOverlayPresented {
//        EmptyView()
//      } else {
//        Group {
//          if showFeedbackInput {
//            /// FeedbackInPutView 여기
//            FeedbackInPutView(
//              teamMembers: vm.teamMembers,
//              feedbackType: feedbackType,
//              currentTime: pointTime,
//              startTime: intervalTime,
//              onSubmit: { content, taggedUserId in
//                Task {
//                  // MARK: - 구간 피드백
//                  if feedbackType == .point {
//                    await vm.feedbackVM.createPointFeedback(
//                      videoId: videoId,
//                      authorId: userId,
//                      content: content,
//                      taggedUserIds: taggedUserId,
//                      atTime: pointTime,
//                      image: self.editedOverlayImage
//                    )
//                  } else { // 시점 피드백
//                    await vm.feedbackVM.createIntervalFeedback(
//                      videoId: videoId,
//                      authorId: userId,
//                      content: content,
//                      taggedUserIds: taggedUserId,
//                      startTime: vm.feedbackVM.intervalStartTime ?? 0,
//                      endTime: vm.videoVM.currentTime,
//                      image: self.editedOverlayImage
//                    )
//                  }
//                  showFeedbackInput = false
//                  
//                  // 피드백 제출 후 스크롤 최상단 이동
//                  DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                    withAnimation {
//                      scrollProxy?.scrollTo("topFeedback", anchor: .top)
//                    }
//                  }
//                }
//              },
//              refresh: {
//                self.showFeedbackInput = false
//                dismissKeyboard()
//              },
//              timeSeek: { vm.videoVM.seekToTime(to: self.pointTime) },
//              drawingButtonTapped: { captureCurrentFrame() },
//              feedbackDrawingImage: $editedOverlayImage,
//              imageNamespace: drawingImageNamespace,
//              showImageFull: $showDrawingImageFull
//            )
//          } else {
//            FeedbackButton(
//              pointAction: {
//                self.feedbackType = .point
//                self.pointTime = vm.videoVM.currentTime
//                self.showFeedbackInput = true // 텍스트 필드로 변하는 시점
//                if vm.videoVM.isPlaying {
//                  vm.videoVM.togglePlayPause()
//                }
//              },
//              intervalAction: {
//                if vm.feedbackVM.isRecordingInterval {
//                  feedbackType = .interval
//                  self.intervalTime = vm.videoVM.currentTime
//                  showFeedbackInput = true
//                  if vm.videoVM.isPlaying {
//                    vm.videoVM.togglePlayPause()
//                  }
//                } else {
//                  feedbackType = .interval
//                  self.pointTime = vm.videoVM.currentTime
//                  _ = vm.feedbackVM.handleIntervalButtonType(currentTime: vm.videoVM.currentTime)
//                }
//              },
//              isRecordingInterval: vm.feedbackVM.isRecordingInterval,
//              startTime: pointTime.formattedTime(),
//              currentTime: vm.videoVM.currentTime.formattedTime(),
//              feedbackType: $feedbackType
//            )
//          }
//        }
//      }
//    }
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
        teamspaceId: teamspaceId?.uuidString ?? ""
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
    .onReceive(NotificationCenter.default.publisher(for: .showCreateReportSuccessToast)) { notification in
      if let toastViewName = notification.userInfo?["toastViewName"] as? ReportToastReceiveViewType,
         toastViewName == .videoView {
        showCreateReportSuccessToast = true
      }
    }
  }

}

#Preview {
  NavigationStack {
    VideoView(
      videoId: "3",
      videoTitle: "벨코의 리치맨",
      videoURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
    )
  }
  .environmentObject(MainRouter())
  .preferredColorScheme(.dark)
}

