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
  
  /// 변경사항 저장하지 않고 뒤로가기 시 나타나는 알럿입니다.
  func unsavedChangesAlert(
    isPresented: Binding<Bool>,
    onConfirm: @escaping () -> Void
  ) -> some View {
    self.alert(
      "변경사항이 저장되지 않았습니다.",
      isPresented: isPresented) {
        Button("취소", role: .cancel) {}
        Button("나가기", role: .destructive) {
          onConfirm()
        }
      } message: {
        Text("저장하지 않은 변경사항은 사라집니다.")
      }
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
  
  /// 커스텀 섹션 글래스 이펙트 버전 분기 뷰빌더 입니다.
  @ViewBuilder
  func sectionChip(isSelected: Bool) -> some View {
    if #available(iOS 26.0, *) {
      self
//        .buttonStyle(.glass)
        .glassEffect(
          isSelected ? .clear.tint(Color(red: 0x7E/255, green: 0x7C/255, blue: 0xFF/255)).interactive() : .clear.tint(.clear).interactive(), in: Capsule()
        )
//        .environment(\.colorScheme, .light)
    } else {
      self
        .background(
          Capsule()
            .fill(isSelected ? .secondaryNormal : Color.fillNormal)
        )
//        .background(isSelected ? .secondaryNormal : Color.fillNormal)
    }
  }
  
  /// 섹션 아이콘 글래스 이펙트 버전 분기 뷰빌더 입니다.
  @ViewBuilder
  func sectionIcon() -> some View {
    if #available(iOS 26.0, *) {
      self
//        .buttonStyle(.glass)
        .glassEffect(.clear.interactive(), in: RoundedRectangle(cornerRadius: 1000))
    } else {
      self
        .background(
          Capsule()
            .fill(Color.fillNormal)
        )
//        .background(Color.fillNormal)
    }
  }
  
  @ViewBuilder
  func uploadGlassButton(isScrollDown: Bool) -> some View {
    if #available(iOS 26.0, *) {
      self
        .glassEffect(.clear.tint(Color(red: 0x7E/255, green: 0x7C/255, blue: 0xFF/255)).interactive(), in: RoundedRectangle(cornerRadius: isScrollDown ? 24 : 1000))
              .environment(\.colorScheme, .light)
    } else {
      self
        .background(
          RoundedRectangle(cornerRadius: isScrollDown ? 24 : 1000)
            .fill(Color.secondaryNormal)
        )
              .environment(\.colorScheme, .light)
    }
  }
  
  @ViewBuilder
  func overlayController() -> some View {
    if #available(iOS 26.0, *) {
      self
        .glassEffect(
          .clear.interactive(),
          in: .circle
        )
    } else {
      self
        .background(
          Circle()
            .fill(Color.black.opacity(0.25))
            .shadow(color: .white.opacity(0.3), radius: 2, x: 0, y: 1)
        )
    }
  }
  // 피드백 타입 전환 버튼
  @ViewBuilder
  func feedbackCircleButton() -> some View {
    if #available(iOS 26.0, *) {
      self
        .glassEffect(
          .clear.tint(Color.black.opacity(0.8)).interactive(),
          in: .circle
        )
    } else {
      self
        .background {
          Circle()
            .fill(Color.black)
            .overlay(.ultraThinMaterial)
        }
        .clipShape(Circle())
    }
  }
  
  @ViewBuilder
  func feedbackPointButton() -> some View {
    if #available(iOS 26.0, *) {
      self
        .glassEffect(.clear.tint(.secondaryNormal).interactive(), in: RoundedRectangle(cornerRadius: 1000))
    } else {
      self
        .background {
          RoundedRectangle(cornerRadius: 1000)
            .fill(Color.blue)
            .overlay(.ultraThinMaterial)
        }
        .clipShape(RoundedRectangle(cornerRadius: 1000))
    }
  }
  
  @ViewBuilder
  func feedbackIntervalButton(isRecording: Bool) -> some View {
    if #available(iOS 26.0, *) {
      self
        .glassEffect(
          .clear.tint(
            (isRecording ? Color.secondaryStrong : Color.secondaryNormal).opacity(0.7)
          ).interactive(),
          in: RoundedRectangle(cornerRadius: 1000)
        )
    } else {
      self
        .background {
          RoundedRectangle(cornerRadius: 1000)
            .fill(isRecording ? Color.purple : Color.blue)
            .overlay(.ultraThinMaterial)
        }
        .clipShape(RoundedRectangle(cornerRadius: 1000))
      }
  }
}
