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

  @State private var animatedIndices: Set<Int> = []

  var body: some View {
    VStack(spacing: 8) {
      // 아이콘 영역
      ZStack {
        Circle()
          .fill(Color.black.opacity(0.6))
          .frame(width: 80, height: 80)

        HStack(spacing: 4) {
          if !isForward {
            chevrons
          }

          Text("\(tapCount * 3)")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.labelStrong)

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
      ForEach(0..<3, id: \.self) { index in
        Image(systemName: isForward ? "chevron.right" : "chevron.left")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(.white)
          .opacity(animatedIndices.contains(index) ? 1.0 : 0.0)
          .scaleEffect(animatedIndices.contains(index) ? 1.0 : 0.5)
      }
    }
  }

  private func playAppearAnimation() {
    animatedIndices = []

    // 나타날 순서 결정 (왼쪽 방향이면 역순으로)
    let appearOrder = isForward ? [0, 1, 2] : [2, 1, 0]

    // 각 셰브론을 차례로 나타나게 함
    for (delay, index) in appearOrder.enumerated() {
      DispatchQueue.main.asyncAfter(deadline: .now() + Double(delay) * 0.1) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
          _ = animatedIndices.insert(index)
        }
      }
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
