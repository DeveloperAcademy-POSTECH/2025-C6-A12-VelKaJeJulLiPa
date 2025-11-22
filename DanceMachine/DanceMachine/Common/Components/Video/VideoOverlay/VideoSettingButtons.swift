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
  let drawingAction: () -> Void

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
        if isLandscapeMode {
          feedbackToggleButton          
        }
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
      drawingButton
      timeButton
    }
  }
  
  private var drawingButton: some View {
    Button {
      drawingAction()
    } label: {
      Image(systemName: "scribble.variable")
        .font(.system(size: 20))
        .foregroundStyle(.labelStrong)
    }
    .frame(width: 44, height: 44)
    .contentShape(Rectangle())
    .overlayController()
  }

  private var feedbackToggleButton: some View {
    Button {
      toggleFeedbackPanel?()
    } label: {
      Image(
        systemName: showFeedbackPanel ? "chevron.right" : "chevron.left"
      )
        .font(.system(size: 20))
        .foregroundStyle(.labelStrong)
    }
    .frame(width: 44, height: 44)
    .contentShape(Rectangle())
    .overlayController()
  }

  private var timeButton: some View {
    Button {
      action()
    } label: {
      Image(.speedometer)
        .font(.system(size: 20))
        .foregroundStyle(.labelStrong)
    }
    .frame(width: 44, height: 44)
    .contentShape(Rectangle())
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
    .contentShape(Rectangle())
    .overlayController()
  }
}

#Preview {
  VideoSettingButtons(
    action: {},
    toggleOrientations: {}, drawingAction: {},
    isLandscapeMode: false,
    toggleFeedbackPanel: {},
    showFeedbackPanel: false
  )
}
