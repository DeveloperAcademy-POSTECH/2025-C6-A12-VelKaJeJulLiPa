//
//  VideoView.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/3/25.
//

import SwiftUI
import AVKit

struct VideoView: View {
  
  @State private var vm: VideoDetailViewModel
  
  @State private var showReplyModal: Bool = false
  
  // TODO: teamSpaceId, userId 전역 받아오기
  
//  init(videoURL: String) {
//    _vm = State(initialValue: VideoDetailViewModel(videoURL: videoURL))
//  }
  init(vm: VideoDetailViewModel, videoTitle: String) {
    _vm = State(initialValue: vm)
    self.videoTitle = videoTitle
  }
  
  let videoTitle: String
  
  var body: some View {
    GeometryReader { g in
      VStack {
        videoView
          .frame(maxHeight: g.size.height * 0.33)
        feedbackSection
        Divider()
        feedbackListView
      }
    }
    .toolbarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarLeadingBackButton(icon: .chevron)
      ToolbarCenterTitle(text: videoTitle)
    }
  }
  // MARK: 비디오 섹션
  private var videoView: some View {
    ZStack {
      VideoController(
        player: vm.videoVM.player ?? AVPlayer()
      )
      .aspectRatio(16/9, contentMode: .fit)
      
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
      } label: { // FIXME: 디자인 수정
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
      teamspaceId: "1",
      authorId: "2",
      videoId: "3",
      videoTitle: "벨코의 리치맨",
      videoURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
    )
  }
  .environmentObject(NavigationRouter())
}
