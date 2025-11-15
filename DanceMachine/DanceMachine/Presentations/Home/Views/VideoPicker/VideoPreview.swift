//
//  VideoPreview.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/5/25.
//

import SwiftUI
import AVKit
import Photos

struct VideoPreview: View {
  
  @Bindable var vm: VideoPickerViewModel
  
  var size: CGFloat
  
  var body: some View {
    
#if DEBUG
    if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
      ZStack {
        Rectangle()
          .fill(Color.gray.opacity(0.3))
          .frame(height: 240)
        Text("프리뷰 용")
          .multilineTextAlignment(.center)
          .font(.headline)
          .foregroundColor(.gray)
      }
    } else {
      realBody
    }
#else
    realBody
#endif
    
  }
  
  private var realBody: some View {
    VStack {
      if vm.isLoading {
        VideoLottieView()
          .frame(maxWidth: .infinity)
          .frame(height: size)
      } else if let p = vm.player {
        VideoPlayer(player: p)
          .aspectRatio(16/9, contentMode: .fit)
      } else {
        Image(.videoEmpty)
          .frame(maxWidth: .infinity)
          .frame(height: size)
      }
    }
    .onChange(of: vm.selectedAsset, { oldValue, newValue in
      if newValue != nil {
        vm.loadVideo()
      } else {
        vm.player = nil
      }
    })
    .ignoresSafeArea()
  }
  
  private var loadingView: some View {
    VStack {
      ProgressView()
        .tint(.white)
        .scaleEffect(1.5)
      Text("로딩 중...")
        .foregroundStyle(.white)
        .padding(.top)
    }
  }
}
//#Preview {
//  NavigationStack {
//    VideoPreview(selectedAsset: .constant(PHAsset()), size: 100, onConfirm: { _, _, _ in })
//  }
//}
