//
//  View.swift
//  DanceMachine
//
//  Created by 김진혁 on 9/29/25.
//

import SwiftUI

extension View {
  
  /// 네비게이션 이동 시 자동으로 생성되는 뒤로가기 버튼을 제거합니다.
  func hideBackButton() -> some View {
    self.navigationBarBackButtonHidden(true)
  }
  
  /// 아무 곳 터치 시, 키보드 창 내립니다.
  func dismissKeyboardOnTap() -> some View {
    self
      .contentShape(Rectangle())
      .onTapGesture {
#if canImport(UIKit)
        UIApplication.shared.sendAction(
          #selector(UIResponder.resignFirstResponder),
          to: nil, from: nil, for: nil
        )
#endif
      }
  }
  
  /// 키보드 창이 내려가는 메서드 입니다.
  func dismissKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }
  
  /// iOS 26 이상에서만 `.glass` 버튼 스타일과 `.glassEffect(.clear)`를 적용하는 뷰 빌더입니다.
  ///
  /// 이 메서드는 주로 `Button` 에 체이닝해서 사용하도록 설계되었습니다.
  /// - iOS 26.0 이상: `buttonStyle(.glass)` 와 `glassEffect(.clear)` 가 적용된 뷰를 반환합니다.
  /// - 그 외 버전: 아무 스타일도 추가하지 않은 원본 뷰(`self`)를 그대로 반환합니다.
  ///
  /// 사용 예:
  /// ```swift
  /// Button("편집") { ... }
  ///   .clearGlassButtonIfAvailable()
  /// ```
  @ViewBuilder
  func clearGlassButtonIfAvailable() -> some View {
    if #available(iOS 26.0, *) {
      self
        .buttonStyle(.glass)
        .glassEffect(.clear)
    } else {
      self
    }
  }
}
