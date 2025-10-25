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
  
  init(videoURL: String) {
    _vm = State(initialValue: VideoDetailViewModel(videoURL: videoURL))
  }
  
  var body: some View {
    GeometryReader { g in
      VStack {
        videoView
          .frame(maxHeight: g.size.height * 0.4)
      }
    }
  }
  
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
      }
    }
  }
  // MARK: 피드백 리스트
  private var feedbackListView: some View {
    ZStack {
      Image(systemName: "circle")
        .resizable()
        .frame(width: 100)
        .frame(height: 100)
      ScrollView {
        LazyVStack {
          //        if vm.feedbackVM.feedbacks.isEmpty {
          //          emptyView
          //        } else {
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
  
//  private var emptyView: some View {
//    VStack(spacing: 16) {
//      Spacer()
//      Image(systemName: "bubble.left.and.bubble.right")
//        .font(.system(size: 48))
//        .foregroundStyle(.gray)
//      Text("피드백이 없습니다")
//        .font(.headline)
//        .foregroundStyle(.gray)
//      Spacer()
//    }
//    .frame(maxWidth: .infinity)
//  }
}

#Preview {
  @Previewable @State var vm: VideoDetailViewModel = .preview
  NavigationStack {
    VideoView(vm: vm, videoTitle: "벨코의 위플래시")
  }
  .environmentObject(NavigationRouter())
}
