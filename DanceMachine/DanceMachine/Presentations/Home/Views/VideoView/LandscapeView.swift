//
//  LandscapeView.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/16/25.
//

import SwiftUI

struct LandscapeView: View {
  @Bindable var vm: VideoDetailViewModel
  
  @Binding var isDragging: Bool
  @Binding var sliderValue: Double
  
  @State private var showSpeedModal: Bool = false
  
  @State private var showFeedbackPanel: Bool = false
  
  @Binding var feedbackFilter: FeedbackFilter
  
  @Binding var pointTime: Double
  @Binding var intervalTime: Double
  
  @Namespace private var feedbackImageNamespace
  
  let filteredFeedback: [Feedback]
  let userId: String
  let proxy: GeometryProxy
  
  var body: some View {
    ZStack(alignment: .bottom) {
      HStack(spacing: 0) {
        // MARK: 비디오 + 컨트롤 영역
        ZStack {
          Color.black
          
          // 비디오
          if let player = vm.videoVM.player {
            VideoController(player: player)
              .aspectRatio(16/9, contentMode: .fit)
              .frame(maxWidth: .infinity, maxHeight: .infinity)
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
          
          // 컨트롤
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
                self.showSpeedModal = true
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
              onToggleFeedbackPanel: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                  showFeedbackPanel.toggle()
                }
              },
              isLandscapeMode: vm.forceShowLandscape,
              showFeedbackPanel: showFeedbackPanel
            )
            .onChange(of: vm.videoVM.currentTime) { _, newValue in
              if !isDragging {
                sliderValue = newValue
              }
            }
            .padding(.horizontal, showFeedbackPanel ? 0 : 44)
            //        .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity)
            .zIndex(10)
          }
        }
        .frame(width: showFeedbackPanel ? proxy.size.width * 0.6 : nil)
        .clipped()
        
        // MARK: 피드백 패널
        if showFeedbackPanel {
          VStack {
            RoundedRectangle(cornerRadius: 8)
              .fill(.backgroundNormal)
              .frame(width: proxy.size.width * 0.4)
              .overlay {
                ZStack {
                  // 피드백 리스트 레이어
                  VStack(spacing: 0) {
                    HStack(spacing: 0) {
                      FeedbackSection(feedbackFilter: $feedbackFilter)
                        .padding(.vertical, 10)
                      Spacer()
                      Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                          showFeedbackPanel = false
                        }
                      } label: {
                        Image(systemName: "xmark.circle")
                          .font(.system(size: 20))
                          .foregroundStyle(.labelStrong)
                      }
                      .frame(width: 33, height: 33)
                      .contentShape(Rectangle())
                    }
                    .padding(.horizontal, 12)
                    Divider().foregroundStyle(.strokeNormal)
                    FeedbackListView(
                      vm: vm,
                      pointTime: $pointTime,
                      intervalTime: $intervalTime,
                      filteredFeedbacks: filteredFeedback,
                      userId: userId
                    )
                    .scrollIndicators(.hidden)
                  }
                  .padding(.horizontal, 4)
                }
              }
          }
          .transition(.move(edge: .trailing))
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .ignoresSafeArea()
      
      // MARK: Speed Sheet 오버레이
      if showSpeedModal {
        Color.black.opacity(0.7)
          .ignoresSafeArea()
          .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
              self.showSpeedModal = false
            }
          }
        
        PlaybackSpeedSheet(
          playbackSpeed: $vm.videoVM.playbackSpeed,
          onSpeedChange: { speed in
            vm.videoVM.setPlaybackSpeed(speed)
          }
        )
        .frame(width: 350, height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .offset(y: -40)
        .transition(.scale.combined(with: .opacity))
      }
    }
  }
}

//#Preview {
//  LandscapeView()
//}
