//
//  FeedbackButton.swift
//  DanceMachine
//
//  Created by 조재훈 on 10/29/25.
//

import SwiftUI

// FIXME: 컬러 폰트 수정
///  ios26 미만 버전 고려 하지 않은 버전입니다.
struct FeedbackButton: View {
  @State private var showIntervalButton: Bool = false
  @Namespace private var buttonNamespace
  
  let pointAction: () -> Void
  let intervalAction: () -> Void
  let isRecordingInterval: Bool
  
  let startTime: String
  let currentTime: String
  
  @Binding var feedbackType: FeedbackType
  
  var body: some View {
//    GlassEffectContainer {
      HStack(spacing: 8) {
        // 왼쪽 버튼
        if showIntervalButton {
          // 구간 피드백 모드일 때: 작은 원형 버튼 (시점으로 전환)
          Button {
            withAnimation(.smooth(duration: 0.35)) {
              self.feedbackType = .point
              showIntervalButton = false
            }
          } label: {
            Image(.intervalFeedback)
              .font(.system(size: 22))
              .foregroundStyle(.labelStrong)
          }
          .frame(width: 48, height: 48)
          .feedbackCircleButton()
          .matchedGeometryEffect(id: "leftButton", in: buttonNamespace)
          .transition(.asymmetric(
            insertion: .scale(scale: 0.4).combined(with: .offset(x: -15)).combined(with: .opacity),
            removal: .scale(scale: 0.4).combined(with: .offset(x: 15)).combined(with: .opacity)
          ))
        } else {
          // 시점 피드백 모드일 때: 큰 시점 피드백 버튼
          Button {
            pointAction()
          } label: {
            HStack {
              Text("시점 피드백")
                .font(.headline1Medium)
                .foregroundStyle(.labelStrong)
              Image(systemName: "bubble.circle")
                .font(.system(size: 22))
                .foregroundStyle(.labelStrong)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
          }
          .feedbackPointButton()
          .matchedGeometryEffect(id: "leftButton", in: buttonNamespace)
          .transition(.asymmetric(
            insertion: .scale(scale: 0.6).combined(with: .opacity),
            removal: .scale(scale: 0.6).combined(with: .opacity)
          ))
        }

        // 오른쪽 버튼
        if showIntervalButton {
          // 구간 피드백 모드일 때: 큰 구간 피드백 버튼
          Button {
            intervalAction()
          } label: {
            HStack {
              if isRecordingInterval {
                Text("구간 선택 중... \(startTime)~\(currentTime)")
                  .font(.headline1Medium)
                  .foregroundStyle(.labelStrong)
                Image(systemName: "stop.circle")
                  .font(.system(size: 22))
                  .foregroundStyle(.labelStrong)
              } else {
                Text("구간 피드백")
                  .font(.headline1Medium)
                  .foregroundStyle(.labelStrong)
                Image(.intervalFeedback)
                  .font(.system(size: 22))
                  .foregroundStyle(.labelStrong)
              }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
          }
          .feedbackIntervalButton(isRecording: isRecordingInterval)
          .matchedGeometryEffect(id: "rightButton", in: buttonNamespace)
          .transition(.asymmetric(
            insertion: .scale(scale: 0.6).combined(with: .opacity),
            removal: .scale(scale: 0.6).combined(with: .opacity)
          ))
        } else {
          // 시점 피드백 모드일 때: 작은 원형 버튼 (구간으로 전환)
          Button {
            withAnimation(.smooth(duration: 0.35)) {
              self.feedbackType = .interval
              showIntervalButton = true
            }
          } label: {
            Image(systemName: "bubble.circle")
              .font(.system(size: 22))
              .foregroundStyle(.labelStrong)
          }
          .frame(width: 48, height: 48)
          .feedbackCircleButton()
          .matchedGeometryEffect(id: "rightButton", in: buttonNamespace)
          .transition(.asymmetric(
            insertion: .scale(scale: 0.4).combined(with: .offset(x: 15)).combined(with: .opacity),
            removal: .scale(scale: 0.4).combined(with: .offset(x: -15)).combined(with: .opacity)
          ))
        }
      }
      .padding(.horizontal, 16)
      .environment(\.colorScheme, .light)
  }
}

#Preview {
  FeedbackButton(
    pointAction: {},
    intervalAction: {},
    isRecordingInterval: true,
    startTime: "",
    currentTime: "",
    feedbackType: .constant(.point)
  )
}
