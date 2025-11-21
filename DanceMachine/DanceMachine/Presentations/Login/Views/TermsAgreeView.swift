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
      let newValue = !isAllTermsAgreed   // 전체동의 상태 반전
      isPrivacyAgreed = newValue
      isTermsOfUseAgreed = newValue
      isAgeValid = newValue
  }
  
  
  var body: some View {
    ZStack {
      Color.backgroundNormal.ignoresSafeArea()
      
      VStack(spacing: 0) {
        //앱로고 및 안내 문구
        HStack {
          VStack(spacing:27) {
            HStack(spacing: 13) {
              Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 68, height: 52)
              Text("DirAct")
                .font(Font.establishRetrosans(.regular, size: 44))
                .foregroundStyle(.secondaryAssitive)
              Spacer()
            }
            
            HStack(spacing:0) {
              Text("서비스 이용을 위해\n이용약관 동의가 필요합니다.")
                .font(.title2SemiBold)
                .foregroundStyle(.labelNormal)
              Spacer()
            }
          }
        }
        
        Spacer() //중간 공백
        
        //약관 동의
        VStack(spacing: 0) {
          //전체 동의
          HStack {
            Text("전체동의")
              .font(.title2SemiBold)
              .foregroundStyle(.labelStrong)
            Spacer()
            Button {
              agreeAll()
            } label: {
              Image(systemName: "checkmark.circle.fill")
                .resizable()
                .foregroundStyle(
                  isAllTermsAgreed ? .labelStrong : .labelAssitive,
                  isAllTermsAgreed ? .secondaryStrong : .fillAssitive)
                .overlay(
                  Circle()
                    .stroke(
                      isAllTermsAgreed ? .secondaryNormal : .labelAssitive,
                      lineWidth: 1
                    )
                )
                .frame(width: 23, height: 23)
            }
          }
          
          Spacer().frame(height: 16)
          
          Divider().foregroundStyle(.strokeStrong)
          
          Spacer().frame(height: 22)
          
          // 약관 동의 항목들
          VStack(spacing: 22) {
            HStack {
              Text("개인정보 처리 방침 동의")
                .underline()
                .font(.headline2SemiBold)
                .foregroundStyle(.labelNormal)
                .onTapGesture {
                  router.push(to: .privacyPolicy)
                }
              Text("(필수)")
                .font(.headline2SemiBold)
                .foregroundStyle(.labelNormal)
              
              Spacer()
              Button {
                isPrivacyAgreed.toggle()
              } label: {
                Image(systemName: "checkmark.circle.fill")
                  .resizable()
                  .foregroundStyle(
                    isPrivacyAgreed ? .labelStrong : .labelAssitive,
                    isPrivacyAgreed ? .secondaryStrong : .fillAssitive)
                  .overlay(
                    Circle()
                      .stroke(
                        isPrivacyAgreed ? .secondaryNormal : .labelAssitive,
                        lineWidth: 1
                      )
                  )
                  .frame(width: 23, height: 23)
              }
            }
            
            
            HStack {
              Text("서비스 이용 약관 동의")
                .underline()
                .font(.headline2SemiBold)
                .foregroundStyle(.labelNormal)
                .onTapGesture {
                  router.push(to: .termsOfUse)
                }
              Text("(필수)")
                .font(.headline2SemiBold)
                .foregroundStyle(.labelNormal)
              
              Spacer()
              Button {
                isTermsOfUseAgreed.toggle()
              } label: {
                Image(systemName: "checkmark.circle.fill")
                  .resizable()
                  .foregroundStyle(
                    isTermsOfUseAgreed ? .labelStrong : .labelAssitive,
                    isTermsOfUseAgreed ? .secondaryStrong : .fillAssitive)
                  .overlay(
                    Circle()
                      .stroke(
                        isTermsOfUseAgreed ? .secondaryNormal : .labelAssitive,
                        lineWidth: 1
                      )
                  )
                  .frame(width: 23, height: 23)
              }
            }
            
            HStack {
              Text("만 14세 이상 확인")
                .font(.headline2SemiBold)
                .foregroundStyle(.labelNormal)
              Text("(필수)")
                .font(.headline2SemiBold)
                .foregroundStyle(.labelNormal)
              
              Spacer()
              Button {
                isAgeValid.toggle()
              } label: {
                Image(systemName: "checkmark.circle.fill")
                  .resizable()
                  .foregroundStyle(
                    isAgeValid ? .labelStrong : .labelAssitive,
                    isAgeValid ? .secondaryStrong : .fillAssitive)
                  .overlay(
                    Circle()
                      .stroke(
                        isAgeValid ? .secondaryNormal : .labelAssitive,
                        lineWidth: 1
                      )
                  )
                  .frame(width: 23, height: 23)
              }
            }
          }
        }
        Spacer().frame(height: 114)
        bottomButton
      }
      .padding()
    }
  }
  
  
  private var bottomButton: some View {
    ActionButton(
      title: "확인",
      color: .secondaryNormal,
      height: 47,
      isEnabled: isAllTermsAgreed
    ) {
      router.push(to: .initialNameSetting)
      //      router.replace(with: .initialNameSetting)
      
    }
  }
  
}

#Preview {
  TermsAgreeView()
}
