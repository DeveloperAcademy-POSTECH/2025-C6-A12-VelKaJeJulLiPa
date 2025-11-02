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
  @State private var buttonSpacing: CGFloat = 4
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
      HStack(spacing: buttonSpacing) {
        // 왼쪽 버튼
        if showIntervalButton {
          // 구간 피드백 모드일 때: 작은 원형 버튼 (시점으로 전환)
          Button {
            self.feedbackType = .point
            // 일시적으로 spacing 줄여서 물방울 합치기
            withAnimation(.spring(response: 0.3, dampingFraction: 0.68)) {
              buttonSpacing = -20
            }

            withAnimation(.spring(response: 0.5, dampingFraction: 0.68)) {
              showIntervalButton = false
            }

            // 0.2초 후 spacing 복원
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
              withAnimation(.spring(response: 0.4, dampingFraction: 0.68)) {
                buttonSpacing = 4
              }
            }
          } label: {
            Image(systemName: "circle.fill")
              .font(.system(size: 24))
              .foregroundStyle(.white)
              .frame(width: 50, height: 50)
          }
          .padding(4)
          .background {
            ZStack {
              Circle().fill(Color.black)
                .overlay(.ultraThinMaterial)
            }
          }
          .clipShape(Circle())
//          .glassEffect(
//            .clear.tint(Color.black.opacity(0.5)).interactive(),
//            in: .circle
//          )
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
            Text("시점 피드백")
              .font(.system(size: 16, weight: .semibold))
              .foregroundStyle(.white)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 16)
          }
          .padding(4)
          .background {
            ZStack {
              RoundedRectangle(cornerRadius: 1000)
                .fill(Color.blue)
                .overlay(.ultraThinMaterial)
            }
          }
          .clipShape(RoundedRectangle(cornerRadius: 1000))
//          .glassEffect(
//            .clear.tint(Color.blue.opacity(0.7)).interactive(),
//            in: RoundedRectangle(cornerRadius: 12)
//          )
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
                  .font(.system(size: 16, weight: .semibold))
                  .foregroundStyle(.white)
                Image(systemName: "stop.circle")
                  .resizable()
                  .frame(width: 22, height: 22)
              } else {
                Text("구간 피드백")
                  .font(.system(size: 16, weight: .semibold))
                  .foregroundStyle(.white)
              }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
          }
          .padding(4)
          .background {
            ZStack {
              RoundedRectangle(cornerRadius: 1000)
                .fill(Color.blue)
                .overlay(.ultraThinMaterial)
            }
          }
          .clipShape(RoundedRectangle(cornerRadius: 1000))
//          .glassEffect(
//            .clear.tint(
//              (isRecordingInterval ? Color.purple : Color.blue).opacity(0.7)
//            ).interactive(),
//            in: RoundedRectangle(cornerRadius: 12)
//          )
          .matchedGeometryEffect(id: "rightButton", in: buttonNamespace)
          .transition(.asymmetric(
            insertion: .scale(scale: 0.6).combined(with: .opacity),
            removal: .scale(scale: 0.6).combined(with: .opacity)
          ))
        } else {
          // 시점 피드백 모드일 때: 작은 원형 버튼 (구간으로 전환)
          Button {
            self.feedbackType = .interval
            // 일시적으로 spacing 줄여서 물방울 합치기
            withAnimation(.spring(response: 0.3, dampingFraction: 0.68)) {
              buttonSpacing = -20
            }

            withAnimation(.spring(response: 0.5, dampingFraction: 0.68)) {
              showIntervalButton = true
            }

            // 0.2초 후 spacing 복원
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
              withAnimation(.spring(response: 0.4, dampingFraction: 0.68)) {
                buttonSpacing = 4
              }
            }
          } label: {
            Image(systemName: "circle.fill")
              .font(.system(size: 24))
              .foregroundStyle(.white)
              .frame(width: 50, height: 50)
          }
          .padding(4)
          .background {
            ZStack {
              Circle()
                .fill(Color.black)
                .overlay(.ultraThinMaterial)
            }
          }
          .clipShape(Circle())
//          .glassEffect(
//            .clear.tint(Color.black.opacity(0.5)).interactive(),
//            in: .circle
//          )
          .matchedGeometryEffect(id: "rightButton", in: buttonNamespace)
          .transition(.asymmetric(
            insertion: .scale(scale: 0.4).combined(with: .offset(x: 15)).combined(with: .opacity),
            removal: .scale(scale: 0.4).combined(with: .offset(x: -15)).combined(with: .opacity)
          ))
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 8)
//    }
  }
}

//#Preview {
//  FeedbackButton()
//}
