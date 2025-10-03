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
}

#Preview {
  VideoView(videoURL: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8")
}
