//
//  TermsAgreeView.swift
//  DanceMachine
//
//  Created by Paidion on 11/20/25.
//

import SwiftUI

struct TermsAgreeView: View {
  @EnvironmentObject private var router: AuthRouter
  
  @State private var isPrivacyAgreed: Bool = false
  @State private var isTermsOfUseAgreed: Bool = false
  @State private var isAgeValid: Bool = false
  
  var isAllTermsAgreed: Bool {
    isPrivacyAgreed && isTermsOfUseAgreed && isAgeValid
  }
  
  private func agreeAll() {
    let newValue = !isAllTermsAgreed // 전체동의 상태 반전
    isPrivacyAgreed = newValue
    isTermsOfUseAgreed = newValue
    isAgeValid = newValue
  }
  
  var body: some View {
    VStack {
      Spacer().frame(height: 40)
      appText
      Spacer()
      temrsTitle
      Spacer().frame(height: 16)
      Divider().foregroundStyle(.strokeNormal)
      Spacer().frame(height: 24)
      termsRow
      Spacer().frame(height: 48)
      bottomButton
      Spacer().frame(height: 16)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 16)
    .background {
      Color.backgroundNormal.ignoresSafeArea()
      DisableSwipeBackGesture()
        .allowsHitTesting(false)
    }
  }
  
  private var appText: some View {
    VStack(alignment: .leading, spacing: 24) {
      Text("DirAct")
        .font(Font.establishRetrosans(.regular, size: 44))
        .foregroundStyle(.secondaryAssitive)
      Text(String(localized: "서비스 이용을 위해\n약관에 동의해 주세요."))
        .font(.title2SemiBold)
        .foregroundStyle(.labelNormal)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
  
  private var temrsTitle: some View {
    HStack {
      Text(String(localized: "전체동의"))
        .font(.title2SemiBold)
        .foregroundStyle(.labelStrong)
      Spacer()
      TermsAgreeCheckButton(
        action: agreeAll,
        isAllTermsAgreed: isAllTermsAgreed
      )
    }
  }
  
  private var termsRow: some View {
    // 약관 동의 항목들
    VStack(spacing: 22) {
      TermsRow(
        text: String(localized: "개인정보 처리 방침 동의"),
        tapAction: { router.push(to: .privacyPolicy) },
        toggleAction: { isPrivacyAgreed.toggle() },
        isAgreed: isPrivacyAgreed,
        isUnderline: true
      )
      
      TermsRow(
        text: String(localized: "서비스 이용 약관 동의"),
        tapAction: { router.push(to: .termsOfUse) },
        toggleAction: { isTermsOfUseAgreed.toggle() },
        isAgreed: isTermsOfUseAgreed,
        isUnderline: true
      )
      
      TermsRow(
        text: String(localized: "저는 14세 이상 입니다."),
        tapAction: {},
        toggleAction: { isAgeValid.toggle() },
        isAgreed: isAgeValid,
        isUnderline: false
      )
    }
  }
  
  private var bottomButton: some View {
    ActionButton(
      title: String(localized: "확인"),
      color: .secondaryNormal,
      height: 47,
      isEnabled: isAllTermsAgreed
    ) {
      router.push(to: .initialNameSetting)
    }
  }
}

#Preview {
  TermsAgreeView()
}
