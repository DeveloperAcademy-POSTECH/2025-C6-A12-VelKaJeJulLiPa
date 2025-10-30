//
//  VideoView.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/3/25.
//

import SwiftUI
import AVKit

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
  
  /// 실제로 보여줄 레이아웃을 결정하는 불리언 변수
  private var shouldShowLayout: Bool {
    isLandscape || forceShowLandscape
  }
  
  // MARK: 배속 좆러
  @State private var showSpeedSheet: Bool = false
  
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
    
  var body: some View {
    GeometryReader { proxy in
      Group {
        if shouldShowLayout {
          landscapeView(proxy: proxy) // 가로모드
        } else {
          portraitView(proxy: proxy) // 세로모드
        }
      }
      .onChange(of: showFeedbackInput) { _, newValue in
        if !newValue {
          vm.feedbackVM.isRecordingInterval = false
        }
      }
      .toolbar(.hidden, for: .tabBar)
    }
    .background(Color.white) // FIXME: 다크모드 배경색 명시
    .overlay {
      if vm.isLoading {
        VStack {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
            .tint(.black)
            .scaleEffect(1)
          
          if vm.videoVM.loadingProgress > 0 {
            Text("다운로드 중... \(Int(vm.videoVM.loadingProgress * 100))%")
              .foregroundStyle(.black)
              .font(.system(size: 14))
          } else {
            Text("로딩 중...")
              .foregroundStyle(.black)
              .font(.system(size: 14))
          }
        }
      }
    } // FIXME: 임시 로딩 뷰
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
    .onAppear { // 화면이 나타날때 세로모드 가로모드를 정함
      updateOrientation()
    }
  }
  
  // MARK: 피드백 빈 화면
  private var pointEmptyView: some View {
    VStack(alignment: .leading) {
      Spacer()
      Text("시점 피드백\n동영상 재생 중 원하는 시점에 버튼을 눌러\n타임스탬프를 남겨 피드백을 작성할 수 있습니다.")
        .font(.system(size: 18))
        .foregroundStyle(.black)
      Spacer()
      Text("구간 피드백\n오른쪽 회색 버튼을 눌러 시작 시점과 끝 시점을\n지정하고, 해당 구간에 대한 피드백을 남길 수 있\n습니다.")
        .font(.system(size: 18))
        .foregroundStyle(.black)
      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .ignoresSafeArea(.keyboard, edges: .bottom)
  }
  
  private var intervalEmptyView: some View {
    VStack(alignment: .leading) {
      Spacer()
      Text("구간 피드백\n동영상 재생 중 시작 시점과 끝 시점을 지정하고\n타임스탬프를 남겨 피드백을 작성할 수 있습니다.")
        .font(.system(size: 18))
        .foregroundStyle(.black)
      Spacer()
      Text("시점 피드백\n회색 버튼을 눌러 원하는 시점에 버튼을 눌러\n타임스탬프를 남겨 피드백을 작성할 수 있습니다.")
        .font(.system(size: 18))
        .foregroundStyle(.black)
      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .ignoresSafeArea(.keyboard, edges: .bottom)
  }
  
  // MARK: 세로모드 레이아웃
  private func portraitView(proxy: GeometryProxy) -> some View {
    VStack(spacing: 0) {
      videoView
        .frame(height: proxy.size.width * 9 / 16)
      
      VStack(spacing: 0) {
        feedbackSection
          .padding(.vertical, 8)
        Divider()
        if vm.feedbackVM.feedbacks.isEmpty {
          switch feedbackType {
          case .point:
            pointEmptyView
          case .interval:
            intervalEmptyView
          }
        } else {
          feedbackListView
            .padding(.top, 16)
        }
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
      Group {
        if showFeedbackInput {
          FeedbackInPutView(
            teamMembers: vm.teamMembers,
            feedbackType: feedbackType,
            currentTime: pointTime,
            startTime: intervalTime,
            onSubmit: { content, taggedUserId in
              Task {
                if feedbackType == .point {
                  await vm.feedbackVM.createPointFeedback(
                    videoId: videoId,
                    authorId: userId,
                    content: content,
                    taggedUserIds: taggedUserId,
                    atTime: pointTime
                  )
                } else {
                  await vm.feedbackVM.createIntervalFeedback(
                    videoId: videoId,
                    authorId: userId,
                    content: content,
                    taggedUserIds: taggedUserId,
                    startTime: vm.feedbackVM.intervalStartTime ?? 0,
                    endTime: vm.videoVM.currentTime
                  )
                }
                showFeedbackInput = false
              }
            },
            refresh: {
              self.showFeedbackInput = false
              dismissKeyboard()
            },
            timeSeek: { vm.videoVM.seekToTime(to: self.pointTime) }
          )
        } else {
          FeedbackButton(
            pointAction: {
              self.feedbackType = .point
              self.pointTime = vm.videoVM.currentTime
              self.showFeedbackInput = true
              vm.videoVM.togglePlayPause()
            },
            intervalAction: {
              if vm.feedbackVM.isRecordingInterval {
                feedbackType = .interval
                self.intervalTime = vm.videoVM.currentTime
                vm.videoVM.togglePlayPause()
                showFeedbackInput = true
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
    .toolbarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarLeadingBackButton(icon: .chevron)
      ToolbarCenterTitle(text: videoTitle)
    }
  }
  
  // MARK: 가로모드 레이아웃
  private func landscapeView(proxy: GeometryProxy) -> some View {
    ZStack {
      // 비디오 + 컨트롤 + 피드백 패널을 함께 회전
      HStack(spacing: 0) {
        // 비디오 플레이어 + 슬라이더 + 버튼
        ZStack {
          // 비디오 (85% width)
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
              showControls: $vm.videoVM.showControls
            )

            if vm.videoVM.showControls {
              OverlayController(
                leftAction: {
                  vm.videoVM.seekToTime(to: vm.videoVM.currentTime - 5)
                },
                rightAction: {
                  vm.videoVM.seekToTime(to: vm.videoVM.currentTime + 5)
                },
                centerAction: {
                  vm.videoVM.togglePlayPause()
                },
                isPlaying: $vm.videoVM.isPlaying
              )
              .padding(.bottom, 20)
            }
          }
          .frame(width: showFeedbackPanel ? proxy.size.height * 0.55 : proxy.size.height * 0.83)

          // 슬라이더 (전체 width로 확장)
          if vm.videoVM.showControls {
            VStack {
              Spacer()

              CustomSlider(
                isDragging: $isDragging,
                currentTime: isDragging ? sliderValue : vm.videoVM.currentTime,
                duration: vm.videoVM.duration,
                onSeek: { time in
                  vm.videoVM.seekToTime(to: time)
                },
                onDragChanged: { time in
                  sliderValue = time
                },
                startTime: vm.videoVM.currentTime.formattedTime(),
                endTime: vm.videoVM.duration.formattedTime()
              )
              .padding(.horizontal, 20)
              .padding(.bottom, 10)
              .onChange(of: vm.videoVM.currentTime) { _, newValue in
                if !isDragging {
                  sliderValue = newValue
                }
              }
            }
            .frame(width: showFeedbackPanel ? proxy.size.height * 0.55 : proxy.size.height)

            // 버튼 (전체 width로 확장)
            VideoSettingButtons(
              action: { self.showSpeedSheet = true },
              toggleOrientations: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                  self.forceShowLandscape.toggle()
                }
              },
              isLandscapeMode: shouldShowLayout,
              toggleFeedbackPanel: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                  showFeedbackPanel.toggle()
                }
              },
              showFeedbackPanel: showFeedbackPanel
            )
            .frame(width: showFeedbackPanel ? proxy.size.height * 0.55 : proxy.size.height)
            .padding(.bottom, 10)
          }
        }
        .frame(width: showFeedbackPanel ? proxy.size.height * 0.55 : proxy.size.height)

        if showFeedbackPanel {
          VStack(spacing: 0) {
            feedbackSection
              .padding(.vertical, 16)
            Divider()
            feedbackListView
              .padding(.vertical, 8)
          }
          .frame(width: proxy.size.height * 0.45)
          .background(Color.black.opacity(0.95))
          .transition(.move(edge: .trailing))
        }
      }
      .frame(width: proxy.size.height, height: proxy.size.width)
      .rotationEffect(.degrees(90))
      .frame(width: proxy.size.width, height: proxy.size.height)
      .clipped()
    }
    .background(Color.black)
  }
  
  private func updateOrientation() {
    let orientation = UIDevice.current.orientation
    switch orientation {
    case .landscapeLeft, .landscapeRight:
      isLandscape = true
      forceShowLandscape = false
    case .portrait, .portraitUpsideDown:
      isLandscape = false
      forceShowLandscape = false
    default:
      break
    }
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
        showControls: $vm.videoVM.showControls
      )
      
      if vm.videoVM.showControls {
        OverlayController(
          leftAction: {
            vm.videoVM.seekToTime(
              to: vm.videoVM.currentTime - 5
            )
          },
          rightAction: {
            vm.videoVM.seekToTime(
              to: vm.videoVM.currentTime + 5
            )
          },
          centerAction: {
            vm.videoVM.togglePlayPause()
          },
          isPlaying: $vm.videoVM.isPlaying
        )
        .padding(.bottom, 20)
        
        CustomSlider(
          isDragging: $isDragging,
          currentTime: isDragging ? sliderValue : vm.videoVM.currentTime,
          duration: vm.videoVM.duration,
          onSeek: { time in
            vm.videoVM.seekToTime(to: time)
          },
          onDragChanged: { time in
            sliderValue = time
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
        
        if !shouldShowLayout {
          VideoSettingButtons(
            action: { self.showSpeedSheet = true },
            toggleOrientations: {
              withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                self.forceShowLandscape.toggle()
              }
            },
            isLandscapeMode: shouldShowLayout,
            toggleFeedbackPanel: {
              withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showFeedbackPanel.toggle()
              }
            },
            showFeedbackPanel: showFeedbackPanel
          )
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
    ScrollView {
      LazyVStack {
        ForEach(filteredFeedbacks, id: \.feedbackId) { f in
          FeedbackCard(
            feedback: f,
            authorUser: vm.getAuthorUser(for: f.authorId),
            taggedUsers:
              vm.getTaggedUsers(for: f.taggedUserIds),
            replyCount: vm.feedbackVM.reply[f.feedbackId.uuidString]?.count ?? 0,
            action: { // showReplySheet와 동일한 네비게이션
              if !shouldShowLayout { // 가로모드 시트 x
                self.selectedFeedback = f
              }
            },
            showReplySheet: { // showReplySheet와 동일한 네비게이션
              if !shouldShowLayout {
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
            }
          )
        }
      }
      .padding(.horizontal, 16)
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
            } }
        )
      }
    }
  }
  // MARK: 피드백 섹션
  private var feedbackSection: some View {
    HStack {
      Text(feedbackFilter == .all ? "전체 피드백" : "마이 피드백")
        .foregroundStyle(.black) // FIXME: 컬러 수정
      Spacer()
      Button {
        switch feedbackFilter {
        case .all:
          self.feedbackFilter = .mine
        case .mine:
          self.feedbackFilter = .all
        }
      } label: {
        Text(feedbackFilter == .all ? "마이 피드백" : "전체 피드백")
        // FIXME: 컬러 폰트 수정
          .foregroundStyle(Color.white)
          .padding(.horizontal, 11)
          .padding(.vertical, 7)
          .background(
            RoundedRectangle(cornerRadius: 10)
              .fill(Color.gray)
              .stroke(Color.white)
          )
      }
    }
    .padding(.horizontal, 16)
  }
  
  // MARK: 피드백 버튼들
  /// 글래스모피즘(물방울 애니메이션) 적용 버튼 컴포넌트로 분리했는데, 버전 대응 고려해서 혹시 모르니 삭제 안하고 주석
//  private var feedbackButtons: some View {
//    HStack(spacing: 12) {
//      // 시점 피드백 버튼
//      Button {
//        feedbackType = .point
//        self.pointTime = vm.videoVM.currentTime
//        vm.videoVM.togglePlayPause()
//        showFeedbackInput = true
//      } label: {
//        Text("시점 피드백")
//          .font(.system(size: 16, weight: .semibold))
//          .foregroundColor(.white)
//          .frame(maxWidth: .infinity)
//          .padding(.vertical, 16)
//          .background(Color.blue)
//          .cornerRadius(12)
//      }
//      
//      // 구간 피드백 버튼
//      Button {
//        if vm.feedbackVM.isRecordingInterval {
//          // 두 번째 클릭: 종료 시간 기록하고 키보드 올림
//          feedbackType = .interval
//          self.intervalTime = vm.videoVM.currentTime
//          vm.videoVM.togglePlayPause()
//          showFeedbackInput = true
//        } else {
//          // 첫 번째 클릭: 시작 시간 기록
//          feedbackType = .interval
//          self.pointTime = vm.videoVM.currentTime
//          _ = vm.feedbackVM.handleIntervalButtonType(currentTime: vm.videoVM.currentTime)
//        }
//      } label: {
//        Text(vm.feedbackVM.isRecordingInterval ? "구간 피드백 중..." : "구간 피드백")
//          .font(.system(size: 16, weight: .semibold))
//          .foregroundColor(.white)
//          .frame(maxWidth: .infinity)
//          .padding(.vertical, 16)
//          .background(vm.feedbackVM.isRecordingInterval ? Color.purple : Color.blue)
//          .cornerRadius(12)
//      }
//    }
//    .padding(.horizontal, 16)
//    .padding(.vertical, 8)
//  }
}

#Preview {
  NavigationStack {
    VideoView(
      videoId: "3",
      videoTitle: "벨코의 리치맨",
      videoURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
    )
  }
  .environmentObject(NavigationRouter())
}
