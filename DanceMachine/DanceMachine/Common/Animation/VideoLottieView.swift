//
//  SwiftUIView.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/9/25.
//

import SwiftUI
import Lottie

/// 비디오 로딩 스피너 입니다.
struct VideoLottieView: View {
  var body: some View {
    VStack {
      LottieView(animation: .named("spinnerPurple"))
        .playing(loopMode: .loop)
        .frame(width: 30, height: 30)
    }
  }
}

#Preview {
  VideoLottieView()
}
