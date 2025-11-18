//
//  VideoControlOverlay.swift
//  DanceMachine
//

import SwiftUI

struct VideoControlOverlay: View {
  @Binding var isDragging: Bool
  @Binding var sliderValue: Double

  let currentTime: Double
  let duration: Double
  let isPlaying: Bool

  let onSeek: (Double) -> Void
  let onDragChanged: (Double) -> Void
  let onLeftAction: () -> Void
  let onRightAction: () -> Void
  let onCenterAction: () -> Void
  let onSpeedAction: () -> Void
  let onToggleOrientation: () -> Void
  let onToggleFeedbackPanel: () -> Void

  let isLandscapeMode: Bool
  let showFeedbackPanel: Bool

  var body: some View {
    ZStack {
      OverlayController(
        leftAction: onLeftAction,
        rightAction: onRightAction,
        centerAction: onCenterAction,
        isPlaying: .constant(isPlaying)
      )
      .padding(.bottom, 20)

      CustomSlider(
        isDragging: $isDragging,
        currentTime: isDragging ? sliderValue : currentTime,
        duration: duration,
        onSeek: onSeek,
        onDragChanged: onDragChanged,
        startTime: currentTime.formattedTime(),
        endTime: duration.formattedTime()
      )
      .padding(.horizontal, 20)

      VideoSettingButtons(
        action: onSpeedAction,
        toggleOrientations: onToggleOrientation,
        isLandscapeMode: isLandscapeMode,
        toggleFeedbackPanel: onToggleFeedbackPanel,
        showFeedbackPanel: showFeedbackPanel
      )
    }
  }
}
