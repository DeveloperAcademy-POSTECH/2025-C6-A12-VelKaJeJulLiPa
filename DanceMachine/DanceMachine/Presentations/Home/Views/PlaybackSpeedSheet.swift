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
  private let maxSpeed: Float = 3.0
  private let speedStep: Float = 0.25
  
  private let presetSpeeds: [Float] = [1.0, 1.25, 1.5, 2.0, 3.0]
  var body: some View {
    VStack {
      Text("\(String(format: "%.2f", playbackSpeed)) X") // FIXME: 폰트, 컬러 수정
        .font(.system(size: 24))
        .foregroundStyle(.white)
      
      HStack {
        Button {
          decreaseSpeed()
        } label: {
          Image(systemName: "minus")
            .font(.system(size: 20))
            .foregroundStyle(.white)
            .frame(width: 50, height: 50)
            .background(Color.gray.opacity(0.3))
            .clipShape(Circle())
        }
        Slider(
          value: Binding(
            get: { playbackSpeed },
            set: { newValue in
              let rounded = round(newValue / speedStep) * speedStep
              updateSpeed(rounded)
            }
          ),
          in: minSpeed...maxSpeed,
          step: speedStep
        )
        .tint(.purple)
        
        Button {
          increaseSpeed()
        } label: {
          Image(systemName: "plus")
            .font(.system(size: 20))
            .foregroundStyle(.white)
            .frame(width: 50, height: 50)
            .background(Color.gray.opacity(0.3))
            .clipShape(Circle())
        }
      }
      .padding(.horizontal, 16)
      
      freeSetButton
    }
    
//    .padding(.vertical, 16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black.opacity(0.9))
  }
  private var freeSetButton: some View {
    HStack {
      ForEach(presetSpeeds, id: \.self) { speed in
        Button {
          updateSpeed(speed)
        } label: {
          Text(formatSpeed(speed))
            .font(.system(size: 16))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 30))
        }
      }
    }
    .padding(.horizontal, 16)
  }
  
  private func updateSpeed(_ speed: Float) {
    self.playbackSpeed = speed
    self.onSpeedChange(speed)
  }
  private func increaseSpeed() {
    let new = min(playbackSpeed + speedStep, maxSpeed)
    updateSpeed(new)
  }
  private func decreaseSpeed() {
    let new = max(playbackSpeed - speedStep, minSpeed)
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
