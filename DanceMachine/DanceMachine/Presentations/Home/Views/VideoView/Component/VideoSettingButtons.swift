//
//  VideoSettingButtons.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/30/25.
//

import SwiftUI

struct VideoSettingButtons: View {
  let action: () -> Void
  let toggleOrientations: () -> Void

  // 가로모드 여부와 피드백 패널 토글
  let isLandscapeMode: Bool
  let toggleFeedbackPanel: (() -> Void)?
  let showFeedbackPanel: Bool

  var body: some View {
    HStack {
      Spacer()
      VStack {
        topButton
          .padding(.top, 10)
        Spacer()
        orientationButton
          .padding(.bottom, 48)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.horizontal, 16)
  }

  // 위쪽 버튼: 세로모드는 배속조절, 가로모드는 피드백 패널 토글
  private var topButton: some View {
    Button {
      if isLandscapeMode {
        toggleFeedbackPanel?()
      } else {
        action()
      }
    } label: {
      Image(systemName: isLandscapeMode
        ? (showFeedbackPanel ? "message" : "message") // FIXME: 수정
        : "deskclock"
      )
      .font(.system(size: 20))
      .foregroundStyle(.white)
      .frame(width: 44, height: 44)
      .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    .contentShape(Rectangle())
  }

  // 아래쪽 버튼: 항상 전체화면 토글
  private var orientationButton: some View {
    Button {
      toggleOrientations()
    } label: {
      Image(systemName: "arrow.up.left.and.arrow.down.right")
        .font(.system(size: 20))
        .foregroundStyle(.white)
        .frame(width: 44, height: 44)
        .clipShape(Rectangle())
    }
    .contentShape(Rectangle())
  }
}

#Preview {
  VideoSettingButtons(
    action: {},
    toggleOrientations: {},
    isLandscapeMode: false,
    toggleFeedbackPanel: {},
    showFeedbackPanel: false
  )
}
