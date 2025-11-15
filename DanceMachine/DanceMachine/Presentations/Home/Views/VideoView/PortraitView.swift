//
//  PortraitView.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/16/25.
//

import SwiftUI

struct PortraitView: View {
  @Bindable var vm: VideoDetailViewModel
  
  @Binding var isDragging: Bool
  @Binding var sliderValue: Double
  
  @Binding var feedbackFilter: FeedbackFilter
  
  @Binding var pointTime: Double
  @Binding var intervalTime: Double
  
  @Binding var showFeedbackInput: Bool
  
  @State private var showSpeedSheet: Bool = false
  
  let filteredFeedback: [Feedback]
  let userId: String
  let proxy: GeometryProxy
  let videoTitle: String
  
  var body: some View {
    VStack(spacing: 0) {
      ZStack {
        if let player = vm.videoVM.player {
          VideoController(player: player)
            .aspectRatio(16/9, contentMode: .fit)
        } else {
          Color.black
            .aspectRatio(16/9, contentMode: .fit)
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
              self.showSpeedSheet = true
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
            onToggleFeedbackPanel: { },
            isLandscapeMode: vm.forceShowLandscape,
            showFeedbackPanel: false
          )
          .onChange(of: vm.videoVM.currentTime) { _, newValue in
            if !isDragging {
              sliderValue = newValue
            }
          }
  //        .frame(maxWidth: .infinity, maxHeight: .infinity)
          .transition(.opacity)
          .zIndex(10)
        }
      }
        .frame(height: proxy.size.width * 9 / 16)
      
      VStack(spacing: 0) {
        FeedbackSection(feedbackFilter: $feedbackFilter)
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
        Divider()
        FeedbackListView(
          vm: vm,
          pointTime: $pointTime,
          intervalTime: $intervalTime,
          filteredFeedbacks: filteredFeedback,
          userId: userId
        )
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
}

//#Preview {
//  PortraitView()
//}
