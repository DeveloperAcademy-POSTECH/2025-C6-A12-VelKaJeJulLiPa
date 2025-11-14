//
//  PlaybackSpeedSheet.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/30/25.
//

import SwiftUI

struct PlaybackSpeedSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Binding var playbackSpeed: Float

  let onSpeedChange: (Float) -> Void

  private let minSpeed: Float = 0.25
  private let maxSpeed: Float = 2.0
  private let speedStep: Float = 0.25

  private let presetSpeeds: [Float] = [0.3, 0.5, 0.9, 0.8, 1.0]

  @State private var tempSpeed: Float = 1.0

  var body: some View {
    VStack(spacing: 16) {
      Text("\(String(format: "%.2f", tempSpeed)) X")
        .font(.headline2Medium)
        .foregroundStyle(.labelStrong)

      HStack {
        Button {
          decreaseSpeed()
        } label: {
          Image(systemName: "minus")
            .font(.system(size: 20))
            .foregroundStyle(.backgroundElevated)
            .frame(width: 44, height: 44)
            .background(.primitiveAssitive)
            .clipShape(Circle())
        }
        Slider(
          value: $tempSpeed,
          in: minSpeed...maxSpeed,
          step: speedStep,
          onEditingChanged: { isEditing in
            if !isEditing {
              let rounded = round(tempSpeed / speedStep) * speedStep
              updateSpeed(rounded)
            }
          }
        )
        .tint(Color.primitiveAssitive)
        .contentShape(Rectangle())

        Button {
          increaseSpeed()
        } label: {
          Image(systemName: "plus")
            .font(.system(size: 20))
            .foregroundStyle(.backgroundElevated)
            .frame(width: 44, height: 44)
            .background(.primitiveAssitive)
            .clipShape(Circle())
        }
      }
      .padding(.horizontal, 16)

      freeSetButton
    }
    .padding(.top, 16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.backgroundElevated)
    .onAppear {
      tempSpeed = playbackSpeed
    }
    .onChange(of: playbackSpeed) { _, newValue in
      tempSpeed = newValue
    }
  }
  private var freeSetButton: some View {
    HStack {
      ForEach(presetSpeeds, id: \.self) { speed in
        Button {
          updateSpeed(speed)
        } label: {
          Text(formatSpeed(speed))
            .font(.caption1Medium)
            .foregroundStyle(.labelStrong)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(.fillAssitive)
            .clipShape(RoundedRectangle(cornerRadius: 30))
        }
      }
    }
    .padding(.horizontal, 16)
  }
  
  private func updateSpeed(_ speed: Float) {
    self.tempSpeed = speed
    self.playbackSpeed = speed
    self.onSpeedChange(speed)
  }
  private func increaseSpeed() {
    let new = min(tempSpeed + speedStep, maxSpeed)
    updateSpeed(new)
  }
  private func decreaseSpeed() {
    let new = max(tempSpeed - speedStep, minSpeed)
    updateSpeed(new)
  }
  private func formatSpeed(_ speed: Float) -> String {
    if speed == 1.0 {
      return "1.0"
    }
    return String(format: "%.1f", speed)
  }
}

#Preview {
  PlaybackSpeedSheet(playbackSpeed: .constant(1.0), onSpeedChange: { _ in })
}
