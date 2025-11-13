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
  
  @State private var vm: VideoDetailViewModel = .init()
  
  @State private var showReplyModal: Bool = false
  @State private var showFeedbackInput: Bool = false
  @State private var feedbackType: FeedbackType = .point
  @State private var feedbackFilter: FeedbackFilter = .all
  
  // MARK: 슬라이더 관련
  @State private var isDragging: Bool = false
  @State private var sliderValue: Double = 0
  
  // MARK: 피드백 시점 관련
  @State private var pointTime: Double = 0
  @State private var intervalTime: Double = 0
  
  // MARK: 답글 관련
  @State private var selectedFeedback: Feedback? = nil
  
  // MARK: 글래스 이팩트 버튼
  @Namespace private var buttonNamespace
  @State private var showIntervalButton: Bool = false
  @State private var buttonSpacing: CGFloat = 4
  
  // MARK: 가로모드 관련
  @State private var isLandscape: Bool = false // 디바이스 가로모드 감지
  @State private var forceShowLandscape: Bool = false // 전체 화면 버튼으로 가는 가로모드
  @State private var showFeedbackPanel: Bool = false
  
  // MARK: 배속 좆러
  @State private var showSpeedSheet: Bool = false
  
  // MARK: 스크롤 관련
  @State private var scrollProxy: ScrollViewProxy? = nil
  
  // MARK: 신고하기 관련
  @State private var reportTargetFeedback: Feedback? = nil
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
        if forceShowLandscape {
          ZStack {
            Color.backgroundNormal.ignoresSafeArea()
            VStack {
              landscapeView(proxy: proxy) // 가로모드
            }
          }
        } else {
          ZStack {
            Color.backgroundNormal.ignoresSafeArea()
            VStack {
              portraitView(proxy: proxy) // 세로모드
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
    .safeAreaInset(edge: .bottom) {
      if forceShowLandscape || isImageOverlayPresented {
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
            FeedbackButton(
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
    .onChange(of: isImageOverlayPresented) { dismissKeyboard() } // 오버레이(이미지 확대)로 교체시 키보드 내리기
    // 드로잉 이미지 확대 시, 툴 바 숨기기 처리
    .toolbar(
      showDrawingImageFull || showFeedbackImageFull ? .hidden : .visible,
      for: .navigationBar
    )
//    .statusBar(hidden: shouldShowLayout)
    .fullScreenCover(isPresented: $showFeedbackPaperDrawingView) {
      if #available(iOS 26.0, *) {
        FeedbackPaperDrawingView(image: $capturedImage) { image in
          editedOverlayImage = image
          self.capturedImage = nil
        }
      }
      else {
        
        // TODO: iOS 26 이하 교체
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
    // MARK: 신고 완료 토스트 리시버
    .onReceive(NotificationCenter.default.publisher(for: .showCreateReportSuccessToast)) { notification in
      if let toastViewName = notification.userInfo?["toastViewName"] as? ReportToastReceiveViewType,
         toastViewName == .videoView {
        showCreateReportSuccessToast = true
      }
    }
  }
  // MARK: 세로모드 레이아웃
  private func portraitView(proxy: GeometryProxy) -> some View {
    VStack(spacing: 0) {
      videoView
        .frame(height: proxy.size.width * 9 / 16)
      
      VStack(spacing: 0) {
        feedbackSection.padding(.vertical, 8)
        Divider()
        feedbackListView
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
    .toolbarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarLeadingBackButton(icon: .chevron)
      ToolbarCenterTitle(text: videoTitle)
    }
  }
  
  // MARK: 가로모드 레이아웃
  private func landscapeView(proxy: GeometryProxy) -> some View {
    ZStack {
      Color.black.ignoresSafeArea()
      
      HStack(spacing: 0) {
        
        // MARK: 왼쪽 - 비디오 영역
        ZStack {
          // 1) 비디오 레이어
          Group {
            if let player = vm.videoVM.player {
              VideoController(player: player)
                .aspectRatio(16/9, contentMode: .fit)
                .clipped()
                .allowsHitTesting(false)
            } else {
              Color.black
            }
          }
          .background(Color.black)
          
          // 2) 탭 영역 (비디오 위)
          TapClearArea(
            leftTap: { vm.videoVM.leftTab() },
            rightTap: { vm.videoVM.rightTap() },
            centerTap: { vm.videoVM.centerTap() },
            showControls: $vm.videoVM.showControls
          )
          .contentShape(Rectangle())
          .frame(
            width: max(
              proxy.size.width,
              proxy.size.height * 16.0 / 9.0
            )
          )
          
          // 3) 오버레이 컨트롤 (재생/일시정지, 슬라이더, 버튼들)
          if vm.videoVM.showControls {
            
            // 중앙 재생/탐색 컨트롤
            OverlayController(
              leftAction: {
                vm.videoVM.seekToTime(to: vm.videoVM.currentTime - 5)
                if vm.videoVM.isPlaying {
                  vm.videoVM.startAutoHideControls()
                }
              },
              rightAction: {
                vm.videoVM.seekToTime(to: vm.videoVM.currentTime + 5)
                if vm.videoVM.isPlaying {
                  vm.videoVM.startAutoHideControls()
                }
              },
              centerAction: {
                vm.videoVM.togglePlayPause()
              },
              isPlaying: $vm.videoVM.isPlaying
            )
            .frame(
              width: max(
                proxy.size.width,
                proxy.size.height * 16.0 / 9.0
              )
            )
            
            
            // 슬라이더
            CustomSlider(
              isDragging: $isDragging,
              currentTime: isDragging ? sliderValue : vm.videoVM.currentTime,
              duration: vm.videoVM.duration,
              onSeek: { time in
                vm.videoVM.seekToTime(to: time)
              },
              onDragChanged: { time in
                self.sliderValue = time
                vm.videoVM.seekToTime(to: time)
              },
              startTime: vm.videoVM.currentTime.formattedTime(),
              endTime: vm.videoVM.duration.formattedTime()
            )
            .frame(
              width: max(
                proxy.size.width,
                proxy.size.height * 16.0 / 9.0
              )
            )
            .onChange(of: vm.videoVM.currentTime) { _, newValue in
              if !isDragging {
                sliderValue = newValue
              }
            }
            
            // 속도 / 전체화면 / 패널 버튼
            VideoSettingButtons(
              action: { self.showSpeedSheet = true },
              toggleOrientations: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                  self.forceShowLandscape.toggle()
                  if self.forceShowLandscape {
                    // 전체 화면 ON → 가로 강제
                    enterLandscapeMode()
                  } else {
                    // 전체 화면 OFF → 세로 복귀
                    exitLandscapeMode()
                  }
                }
              },
              isLandscapeMode: forceShowLandscape,
              toggleFeedbackPanel: {
                print("토글 눌림")
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                  showFeedbackPanel.toggle()
                }
              },
              showFeedbackPanel: showFeedbackPanel
            )
            .frame(
              width: max(
                proxy.size.width,
                proxy.size.height * 16.0 / 9.0
              )
            )
          }
        }
        
        // MARK: 오른쪽 - 피드백 패널
        if showFeedbackPanel {
          VStack(spacing: 0) {
            HStack(spacing: 0) {
              feedbackSection
                .padding(.vertical, 16)
              
              Button {
                self.showFeedbackPanel = false
              } label: {
                Image(systemName: "xmark.circle")
                  .font(.system(size: 20))
                  .foregroundStyle(.labelStrong)
              }
              .frame(width: 44, height: 44)
            }
            Divider()
            feedbackListView
              .padding(.vertical, 8)
          }
          .onAppear(perform: {
            print("보인다")
          })
          .frame(width: proxy.size.width * 0.4, height: proxy.size.height)
          .background(Color.black.opacity(0.95))
          .transition(.move(edge: .trailing))
        }
      }
    }
    .ignoresSafeArea()
  }
  
  // MARK: 비디오 섹션
  private var videoView: some View {
    ZStack {
      if let player = vm.videoVM.player {
        VideoController(player: player)
          .aspectRatio(16/9, contentMode: .fit)
      } else {
        Color.black
          .aspectRatio(16/9, contentMode: .fit)
      }
      
      TapClearArea(
        leftTap: { vm.videoVM.leftTab() },
        rightTap: { vm.videoVM.rightTap() },
        centerTap: { vm.videoVM.centerTap() },
        showControls: $vm.videoVM.showControls
      )
      
      if vm.videoVM.showControls {
        OverlayController(
          leftAction: {
            vm.videoVM.seekToTime(
              to: vm.videoVM.currentTime - 5
            )
            if vm.videoVM.isPlaying {
              vm.videoVM.startAutoHideControls()
            }
          },
          rightAction: {
            vm.videoVM.seekToTime(
              to: vm.videoVM.currentTime + 5
            )
            if vm.videoVM.isPlaying {
              vm.videoVM.startAutoHideControls()
            }
          },
          centerAction: {
            vm.videoVM.togglePlayPause()
          },
          isPlaying: $vm.videoVM.isPlaying
        )
        .padding(.bottom, 20)
        .transition(.opacity)
        
        CustomSlider(
          isDragging: $isDragging,
          currentTime: isDragging ? sliderValue : vm.videoVM.currentTime,
          duration: vm.videoVM.duration,
          onSeek: { time in
            vm.videoVM.seekToTime(to: time)
          },
          onDragChanged: { time in
            self.sliderValue = time
            vm.videoVM.seekToTime(to: time)
          },
          startTime: vm.videoVM.currentTime.formattedTime(),
          endTime: vm.videoVM.duration.formattedTime()
        )
        .padding(.horizontal, 20)
        .onChange(of: vm.videoVM.currentTime) { _, newValue in
          if !isDragging {
            sliderValue = newValue
          }
        }
        .transition(.opacity)
        
        if !forceShowLandscape {
          VideoSettingButtons(
            action: { self.showSpeedSheet = true },
            toggleOrientations: {
              withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                self.forceShowLandscape.toggle()
                      if self.forceShowLandscape {
                        enterLandscapeMode()
                      } else {
                        exitLandscapeMode()
                      }
              }
            },
            isLandscapeMode: forceShowLandscape,
            toggleFeedbackPanel: {
              withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showFeedbackPanel.toggle()
              }
            },
            showFeedbackPanel: showFeedbackPanel
          )
          .transition(.opacity)
        }
      }
    }
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
    .sheet(isPresented: $showSpeedSheet) {
      PlaybackSpeedSheet(
        playbackSpeed: $vm.videoVM.playbackSpeed) { speed in
          vm.videoVM.setPlaybackSpeed(speed)
        }
        .presentationDetents([.fraction(0.25)])
    }
  }
  // MARK: 피드백 리스트
  private var feedbackListView: some View {
    ScrollViewReader { proxy in
      ScrollView {
        LazyVStack {
          Color.clear.frame(height: 1).id("topFeedback")
          
          if vm.feedbackVM.isLoading {
            ForEach(0..<3, id: \.self) { _ in
              SkeletonFeedbackCard()
            }
          } else if vm.feedbackVM.feedbacks.isEmpty && !vm.feedbackVM.isLoading {
            emptyView
          } else {
            ForEach(filteredFeedbacks, id: \.feedbackId) { f in
              FeedbackCard(
                feedback: f,
                authorUser: vm.getAuthorUser(for: f.authorId),
                taggedUsers:
                  vm.getTaggedUsers(for: f.taggedUserIds),
                replyCount: vm.feedbackVM.reply[f.feedbackId.uuidString]?.count ?? 0,
                action: { // showReplySheet와 동일한 네비게이션
                  if !forceShowLandscape { // 가로모드 시트 x
                    self.selectedFeedback = f
                  }
                },
                showReplySheet: { // showReplySheet와 동일한 네비게이션
                  if !forceShowLandscape {
                    self.selectedFeedback = f
                  }
                },
                currentTime: pointTime,
                startTime: intervalTime,
                timeSeek: { vm.videoVM.seekToTime(to: f.startTime ?? self.pointTime ) },
                currentUserId: userId,
                onDelete: {
                  Task {
                    await vm.feedbackVM.deleteFeedback(f)
                  }
                },
                onReport: {
                  if !forceShowLandscape { // 가로모드 시트 x
                    self.reportTargetFeedback = f
                  }
                },
                imageNamespace: feedbackImageNamespace,
                onImageTap: { url in
                  self.selectedFeedbackImageURL = url
                  withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    self.showFeedbackImageFull = true
                  }
                }
              )
            }
          }
          
        }
        .onAppear {
          self.scrollProxy = proxy
        }
        .sheet(item: $selectedFeedback) { feedback in
          ReplySheet(
            reply: vm.feedbackVM.reply[feedback.feedbackId.uuidString] ?? [],
            feedback: feedback,
            taggedUsers: vm.getTaggedUsers(for: feedback.taggedUserIds),
            teamMembers: vm.teamMembers,
            replyCount: vm.feedbackVM.reply[feedback.feedbackId.uuidString]?.count ?? 0,
            currentTime: pointTime,
            startTime: intervalTime,
            timeSeek: { vm.videoVM.seekToTime(to: self.pointTime) },
            getTaggedUsers: { ids in vm.getTaggedUsers(for: ids) },
            getAuthorUser: { ids in vm.getAuthorUser(for: ids) },
            onReplySubmit: {content, taggedIds in
              Task {
                await vm.feedbackVM.addReply(
                  to: feedback.feedbackId.uuidString,
                  authorId: userId,
                  content: content,
                  taggedUserIds: taggedIds
                )
              }
            },
            currentUserId: userId,
            onDelete: { replyId, feedbackId in
              await vm.feedbackVM.deleteReply(
                replyId: replyId, from: feedbackId)
            },
            onFeedbackDelete: {
              Task {
                await vm.feedbackVM.deleteFeedback(feedback)
              }
            },
            imageNamespace: feedbackImageNamespace,
            onImageTap: { url in
              self.selectedFeedbackImageURL = url
              withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                self.showFeedbackImageFull = true
              }
            }
          )
        }
        .sheet(item: $reportTargetFeedback) { feedback in
          NavigationStack {
            CreateReportView(
              reportedId: feedback.authorId,
              reportContentType: .feedback,
              feedback: feedback,
              toastReceiveView: ReportToastReceiveViewType.videoView
            )
          }
        }
      }
    }
    //    .background(.backgroundNormal)
  }
  // MARK: 피드백 섹션
  private var feedbackSection: some View {
    HStack {
      Text(feedbackFilter == .all ? "전체 피드백" : "마이 피드백")
        .font(.heading1SemiBold)
        .foregroundStyle(.labelStrong)
      Spacer()
      Button {
        switch feedbackFilter {
        case .all:
          self.feedbackFilter = .mine
        case .mine:
          self.feedbackFilter = .all
        }
      } label: {
        Text("마이피드백")
          .foregroundStyle(feedbackFilter == .all ? .secondaryAssitive : .labelStrong)
          .padding(.horizontal, 11)
          .padding(.vertical, 7)
          .background(
            RoundedRectangle(cornerRadius: 10)
              .fill(feedbackFilter == .all ? .backgroundElevated : .secondaryStrong)
              .stroke(feedbackFilter == .all ? .secondaryAssitive : .secondaryNormal)
          )
      }
    }
    .padding(.horizontal, 16)
  }
  // MARK: 피드백 비어있는 emptyView
  private var emptyView: some View {
    GeometryReader { g in
      VStack {
        Text("피드백이 없습니다.")
      }
      .frame(width: g.size.width, height: g.size.height)
    }
    .frame(height: 300)
  }
  /// 현재 플레이어 시점의 프레임을 이미지로 캡쳐
  private func captureCurrentFrame() {
    guard let player = vm.videoVM.player,
          let asset = player.currentItem?.asset else {
      return
    }
    
    let time = player.currentTime()
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    generator.requestedTimeToleranceAfter  = .zero   // 가능한 정확하게
    generator.requestedTimeToleranceBefore = .zero
    
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
        let image   = UIImage(cgImage: cgImage)
        DispatchQueue.main.async {
          self.capturedImage = image
          self.showFeedbackPaperDrawingView = true
          print("이미지 캡처 성공")
        }
      } catch {
        print("⚠️ frame capture error:", error)
      }
    }
  }
  
  @MainActor
  func enterLandscapeMode() {
   
    AppDelegate.orientationMask = .landscape
    
    guard let scene = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .first else { return }
    
    scene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
    
    scene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight))
    
    forceShowLandscape = true
  }
  
  @MainActor
  func exitLandscapeMode() {
    AppDelegate.orientationMask = .portrait
    
    guard let scene = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .first else { return }
    
    scene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
    
    
    scene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
    
    forceShowLandscape = false
  }
  
}

extension UIWindowScene {
  var keyWindow: UIWindow? {
    windows.first { $0.isKeyWindow }
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

