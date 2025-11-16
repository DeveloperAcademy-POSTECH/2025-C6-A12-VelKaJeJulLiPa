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
  }

  private var chevrons: some View {
    HStack(spacing: -4) {
      ForEach(0..<3, id: \.self) { index in
        Image(systemName: isForward ? "chevron.right" : "chevron.left")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(.white)
          .opacity(Double(index + 1) / 3.0)
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
