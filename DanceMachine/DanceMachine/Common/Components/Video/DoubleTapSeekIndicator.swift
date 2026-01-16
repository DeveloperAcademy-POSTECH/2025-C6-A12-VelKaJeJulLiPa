//
//  DoubleTapSeekIndicator.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/17/25.
//

import SwiftUI

struct DoubleTapSeekIndicator: View {
  let isForward: Bool
  let tapCount: Int

  @State private var offset: CGFloat = 0
  @State private var opacity: Double = 0

  var body: some View {
    VStack(spacing: 8) {
      // 아이콘 영역
      ZStack {
//        Circle()
//          .fill(Color.black.opacity(0.6))
//          .frame(width: 80, height: 80)

        HStack(spacing: 4) {
          if !isForward {
            chevrons
          }
          HStack(spacing: 1) {
            Text(isForward ? "+" : "-")
              .font(.headline1Medium)
              .foregroundStyle(.labelStrong)
            Text("\(tapCount * 3)")
              .font(.headline1Medium)
              .foregroundStyle(.labelStrong)
          }

          if isForward {
            chevrons
          }
        }
      }
    }
    .transition(.asymmetric(
      insertion: .scale(scale: 0.8).combined(with: .opacity),
      removal: .scale(scale: 1.2).combined(with: .opacity)
    ))
    .onAppear {
      playAppearAnimation()
    }
    .onChange(of: tapCount) { _, _ in
      // tapCount가 변경될 때마다 애니메이션 재시작
      playAppearAnimation()
    }
  }

  private var chevrons: some View {
    HStack(spacing: -4) {
      ForEach(0..<1, id: \.self) { index in
        Image(systemName: isForward ? "forward.fill" : "backward.fill")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(.white)
          .opacity(opacity)
          .offset(x: offset)
      }
    }
  }

  private func playAppearAnimation() {
    // 초기 상태 설정
    offset = isForward ? -8 : 8
    opacity = 0

    // 애니메이션 시작 - 마지막 위치에서 유지
    withAnimation(.easeOut(duration: 0.3)) {
      offset = isForward ? 4 : -4
      opacity = 1
    }
  }
}

#Preview {
  ZStack {
    Color.gray.ignoresSafeArea()

    HStack(spacing: 100) {
      DoubleTapSeekIndicator(isForward: false, tapCount: 2)
      DoubleTapSeekIndicator(isForward: true, tapCount: 3)
    }
  }
}
