//
//  FeedbackButton.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/29/25.
//

import SwiftUI

struct FeedbackButtons: View {
  
  let landScape: Bool
  
  let pointAction: () -> Void
  let intervalAction: () -> Void
  let isRecordingInterval: Bool
  
  let startTime: String
  let currentTime: String
  
  @Binding var feedbackType: FeedbackType
  
  var body: some View {
    HStack {
      if isRecordingInterval {
        intervalButton
      } else {
        intervalButton
        pointButton
      }
    }
    .animation(
      .smooth(duration: 0.35),
      value: isRecordingInterval
    )
    .padding(.horizontal, 16)
    .frame(maxWidth: .infinity)
    .padding(.vertical, 20)
    .background {
      LinearGradient(
      stops: [
      Gradient.Stop(color: Color(red: 0, green: 0.01, blue: 0.04).opacity(0), location: 0.00),
      Gradient.Stop(color: Color(red: 0, green: 0.01, blue: 0.04).opacity(0.98), location: 0.93),
      ],
      startPoint: UnitPoint(x: 0.5, y: 0),
      endPoint: UnitPoint(x: 0.5, y: 1)
      )
      .ignoresSafeArea()
    }
  }
  
  private var pointButton: some View {
    Button {
      pointAction()
    } label: {
      HStack {
        Text("시점 피드백")
          .font(.headline1Medium)
          .foregroundStyle(.labelStrong)
        Image(systemName: "bubble.circle")
          .font(.system(size: 20))
          .foregroundStyle(.labelStrong)
      }
      .padding(.horizontal, 4)
      .padding(.vertical, 14)
      .frame(maxWidth: .infinity)
      .feedbackPointButton()
    }
  }
  
  private var intervalButton: some View {
    Button {
      intervalAction()
    } label: {
      HStack {
        if isRecordingInterval {
          Text("구간 선택 중... \(startTime)~\(currentTime)")
            .font(.headline1Medium)
            .foregroundStyle(.primitiveButton)
          Image(systemName: "stop.circle")
            .foregroundStyle(.primitiveButton)
        } else {
          Text("구간 피드백")
            .font(.headline1Medium)
            .foregroundStyle(.primitiveButton)
          Image(.feedbackButton)
            .foregroundStyle(.primitiveButton)
        }
      }
      .padding(.horizontal, 4)
      .padding(.vertical, 14)
      .frame(maxWidth: .infinity)
      .feedbackIntervalButton()
    }
  }
}

#Preview {
  FeedbackButtons(
    landScape: true, pointAction: {},
    intervalAction: {},
    isRecordingInterval: false,
    startTime: "",
    currentTime: "",
    feedbackType: .constant(.point)
  )
}
