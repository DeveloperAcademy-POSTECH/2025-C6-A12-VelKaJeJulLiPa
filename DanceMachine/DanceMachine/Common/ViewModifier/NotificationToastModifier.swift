//
//  NotificationToastModifier.swift
//  DanceMachine
//
//  Created by 조재훈 on 11/19/25.
//

import Foundation
import SwiftUI

/// Notification으로 토스트를 띄울때 .toast와 .onReceive로 뷰가 길어지는걸 방지하기 위해 만든 재사용 토스트+리시버 모디파이어 입니다.
struct NotificationToastModifier: ViewModifier {
  @Binding var isPresented: Bool
  let text: String
  let icon: ToastIcon
  let notificationType: NotificationEvent
  let duration: TimeInterval
  let position: ToastPosition
  let bottomPadding: CGFloat
  let tapToDismiss: Bool
  let targetViewType: ReportToastReceiveViewType? // 파이디온 확인 필요
  
  func body(content: Content) -> some View {
    content
      .toast(
        isPresented: $isPresented,
        duration: duration,
        position: position,
        tapToDismiss: tapToDismiss,
        bottomPadding: bottomPadding) {
          ToastView(text: text, icon: icon)
        }
        .onReceive(NotificationCenter.publisher(for: notificationType)) { notification in
          if let target = targetViewType {
            if let viewType = notification.userInfo?["toastViewName"] as? ReportToastReceiveViewType, viewType == target {
              self.isPresented = true
            }
          } else {
            self.isPresented = true
          }
        }
  }
}

extension View {
  
  /// - Parameters:
  ///   - isPresented: 바인딩 값
  ///   - text: ToastView에 들어갈 텍스트
  ///   - icon: ToastView에 들어갈 ToastIcon
  ///   - notificationType: 지정한 notification 타입
  ///   - duration: 토스트 시간
  ///   - position: 토스트 위치
  ///   - bottomPadding: 토스트 패딩 (버튼 있을때 없을때를 고려하여 뷰에서 직접 넣어주도록 하였습니다)
  ///   - tapToDismiss: 탭하여 없애는 bool
  ///   - targetViewType: 이게 정확히 뭔가요..? 파이디온 수정 필요
  func notificationToast(
    isPresented: Binding<Bool>,
    text: String,
    icon: ToastIcon,
    for notificationType: NotificationEvent,
    duration: TimeInterval = 2.0,
    position: ToastPosition = .bottom,
    bottomPadding: CGFloat,
    tapToDismiss: Bool = true,
    targetViewType: ReportToastReceiveViewType? = nil
  ) -> some View {
    modifier(
      NotificationToastModifier(
        isPresented: isPresented,
        text: text,
        icon: icon,
        notificationType: notificationType,
        duration: duration,
        position: position,
        bottomPadding: bottomPadding,
        tapToDismiss: tapToDismiss,
        targetViewType: targetViewType
      )
    )
  }
}
