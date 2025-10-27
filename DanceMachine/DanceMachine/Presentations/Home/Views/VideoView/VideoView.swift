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
  
  // MARK: 슬라이더 관련
  @State private var isDragging: Bool = false
  @State private var sliderValue: Double = 0
  
  // MARK: 피드백 시점 관련
  @State private var pointTime: Double = 0
  @State private var intervalTime: Double = 0
  
  // TODO: teamSpaceId, userId 전역 받아오기
  let teamspaceId = FirebaseAuthManager.shared.currentTeamspace?.teamspaceId
  let userId = FirebaseAuthManager.shared.userInfo?.userId ?? ""
  
  init( // 전역에서 받아온 후 초기화 뺴주기 + 네비게이션 라우터 빼주기
    //    teamspaceId: String,
    //    authorId: String,
    videoId: String,
    videoTitle: String,
    videoURL: String
  ) {
    //    self.teamspaceId = teamspaceId
    //    self.authorId = authorId
    self.videoId = videoId
    self.videoTitle = videoTitle
    self.videoURL = videoURL
  }
  
  //  let teamspaceId: String
  //  let authorId: String // 비디오 작성자가 아닌 피드백 작성자 기준임. 로그인한 사용자
  let videoId: String
  let videoTitle: String
  let videoURL: String
  
  var body: some View {
    GeometryReader { proxy in
      VStack(spacing: 0) {
        videoView
          .frame(height: proxy.size.width * 9 / 16)
        
        VStack(spacing: 0) {
          feedbackSection
            .padding(.vertical, 8)
          Divider()
          feedbackListView
            .padding(.top, 16)
        }
        .contentShape(Rectangle())
        .onTapGesture {
          if showFeedbackInput {
            showFeedbackInput = false
            dismissKeyboard()
          }
        }
      }
      .onChange(of: showFeedbackInput) { _, newValue in
        if !newValue {
          vm.feedbackVM.isRecordingInterval = false
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
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(uiColor: .systemBackground))
          } else {
            feedbackButtons
          }
        }
      }
      .toolbar(.hidden, for: .tabBar)
      .toolbarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarLeadingBackButton(icon: .chevron)
        ToolbarCenterTitle(text: videoTitle)
      }
    }
    .overlay {
      if vm.isLoading {
        VStack {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
            .tint(.purple)
            .scaleEffect(2)
          
          if vm.videoVM.loadingProgress > 0 {
            Text("다운로드 중... \(Int(vm.videoVM.loadingProgress * 100))%")
              .foregroundStyle(.purple)
              .font(.system(size: 25))
          } else {
            Text("로딩 중...")
              .foregroundStyle(.purple)
              .font(.system(size: 25))
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
        
      }
    }
    .overlay { // FIXME: 비디오 로딩뷰 논의 -> 오래동안 보는 뷰라 중요도 있다 생각함
      if vm.videoVM.isLoading {
        VStack {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
            .tint(.white)
            .scaleEffect(1.5)
          
          if vm.videoVM.loadingProgress > 0 {
            Text("다운로드 중... \(Int(vm.videoVM.loadingProgress * 100))%")
              .foregroundStyle(.white)
              .font(.system(size: 14))
          } else {
            Text("로딩 중...")
              .foregroundStyle(.white)
              .font(.system(size: 14))
          }
        }
        .aspectRatio(16/9, contentMode: .fit)
      }
    }
  }
  
  // MARK: 피드백 리스트
  private var feedbackListView: some View {
    ScrollView {
      LazyVStack {
        ForEach(vm.feedbackVM.feedbacks, id: \.feedbackId) { f in
          FeedbackCard(
            feedback: f,
            taggedUsers:
              vm.getTaggedUsers(for: f.taggedUserIds),
            replyCount: vm.feedbackVM.reply[f.feedbackId.uuidString]?.count ?? 0,
            action: { self.showReplyModal = true }
          )
        }
      }
      .padding(.horizontal, 16)
    }
  }
  
  // MARK: 피드백 섹션
  private var feedbackSection: some View {
    HStack {
      Text("전체 피드백")
      Spacer()
      Button {
        // TODO: 피드백 필터링 기능
      } label: {
        Text("마이 피드백")
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
  private var feedbackButtons: some View {
    HStack(spacing: 12) {
      // 시점 피드백 버튼
      Button {
        feedbackType = .point
        self.pointTime = vm.videoVM.currentTime
        vm.videoVM.togglePlayPause()
        showFeedbackInput = true
      } label: {
        Text("시점 피드백")
          .font(.system(size: 16, weight: .semibold))
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 16)
          .background(Color.blue)
          .cornerRadius(12)
      }
      
      // 구간 피드백 버튼
      Button {
        if vm.feedbackVM.isRecordingInterval {
          // 두 번째 클릭: 종료 시간 기록하고 키보드 올림
          feedbackType = .interval
          self.intervalTime = vm.videoVM.currentTime
          vm.videoVM.togglePlayPause()
          showFeedbackInput = true
        } else {
          // 첫 번째 클릭: 시작 시간 기록
          feedbackType = .interval
          self.pointTime = vm.videoVM.currentTime
          _ = vm.feedbackVM.handleIntervalButtonType(currentTime: vm.videoVM.currentTime)
        }
      } label: {
        Text(vm.feedbackVM.isRecordingInterval ? "구간 피드백 중..." : "구간 피드백")
          .font(.system(size: 16, weight: .semibold))
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 16)
          .background(vm.feedbackVM.isRecordingInterval ? Color.purple : Color.blue)
          .cornerRadius(12)
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
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
  .environmentObject(NavigationRouter())
}
