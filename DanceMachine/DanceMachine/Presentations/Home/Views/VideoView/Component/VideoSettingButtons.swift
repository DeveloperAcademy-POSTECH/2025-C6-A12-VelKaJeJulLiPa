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
      VStack(alignment: .trailing) {
        topButton
          .padding(.top, 10)
        Spacer()
        orientationButton
          .padding(.bottom, 54)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.horizontal, 16)
  }
  
  private var topButton: some View {
    HStack(spacing: 15) {
      if isLandscapeMode { // 가로모드일때
        feedbackToggleButton
        timeButton
      } else if showFeedbackPanel { // 피드백 패널 열렸을때
        timeButton
      } else { // 세로모드일때
        timeButton
      }
    }
  }
  
  private var feedbackToggleButton: some View {
    Button {
      toggleFeedbackPanel?()
    } label: {
      Image(systemName: "message")
        .font(.system(size: 20))
        .foregroundStyle(.labelStrong)
    }
    .frame(width: 44, height: 44)
    .overlayController()
  }
  
  private var timeButton: some View {
    Button {
      action()
    } label: {
      Image(systemName: "clock.arrow.trianglehead.clockwise.rotate.90.path.dotted")
        .font(.system(size: 20))
        .foregroundStyle(.labelStrong)
    }
    .frame(width: 44, height: 44)
    .overlayController()
  }

  // 아래쪽 버튼: 항상 전체화면 토글
  private var orientationButton: some View {
    Button {
      toggleOrientations()
    } label: {
      Image(systemName: isLandscapeMode ? "arrow.up.right.and.arrow.down.left.rectangle" : "arrow.down.left.and.arrow.up.right.rectangle")
        .font(.system(size: 20))
        .foregroundStyle(.labelStrong)
    }
    .frame(width: 44, height: 44)
    .overlayController()
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
